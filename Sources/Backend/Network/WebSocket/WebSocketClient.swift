import Foundation
import Starscream

/// Protocol for managing WebSocket connections
/// To mark the Starscream's WebSocket class
protocol WebSocketProtocol: AnyObject, AutoMockable {

    /// Indicates whether the connection is established
    var isConnected: Bool { get }

    /// Closure called when the connection is established
    var onConnect: (() -> Void)? { get set }

    /// Closure called when the connection is disconnected
    /// - Parameter error: Error if the disconnection occurred due to an error
    var onDisconnect: ((Error?) -> Void)? { get set }

    /// Closure called when an update is received
    /// - Parameter text: The received text message
    var onText: ((String) -> Void)? { get set }

    /// Closure called when HTTP response headers are received
    /// - Parameter headers: The received HTTP headers
    var onHttpResponseHeaders: (([String: String]) -> Void)? { get set }

    /// Establishes the WebSocket connection
    func connect()

    /// Disconnects the WebSocket connection
    /// - Parameters:
    ///   - forceTimeout: The timeout for forced disconnection
    ///   - closeCode: The code for closing the connection
    func disconnect(forceTimeout: TimeInterval?, closeCode: UInt16)
}

extension WebSocket: WebSocketProtocol { }

protocol WebSocketClientProtocol: AnyObject, AutoMockable {
    var isConnected: Bool { get }

    var onChannelUpdate: ((String) -> Void)? { get set }
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }

    func connect()
    func disconnect()
}

final class WebSocketClient: WebSocketClientProtocol {
    private static let endpoint = "/messages"

    private let socket: WebSocketProtocol

    private let authState: AuthStateProtocol

    var isConnected: Bool {
        socket.isConnected
    }

    /// Callback to get channel updates emitted by web socket
    var onChannelUpdate: ((String) -> Void)?

    /// Callback to get info about successful connection
    var onConnect: (() -> Void)?

    /// Callback to get info about disconnection
    var onDisconnect: ((Error?) -> Void)?

    init(baseURL: URL, authState: AuthStateProtocol, socket: WebSocketProtocol? = nil) {
        if authState.accessToken == nil {
            assertionFailure("Passed invalid AuthState: accessToken should be set")
        }

        self.socket = socket ?? WebSocket(
            url: Self.makeWebSocketURLFromBaseURL(
                url: baseURL,
                token: authState.accessToken ?? ""
            )
        )
        self.authState = authState

        self.setupSocket()
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect(
            forceTimeout: nil,
            closeCode: CloseCode.normal.rawValue
        )
    }
}

// MARK: - Private

private extension WebSocketClient {

    func setupSocket() {
        socket.onText = { [weak self] in
            self?.onChannelUpdate?($0)
        }

        socket.onConnect = { [weak self] in
            log(sender: self, "ws client: connected")
            self?.onConnect?()
        }

        socket.onHttpResponseHeaders = { [weak self] headers in
            let id = headers.first(where: { $0.key.lowercased() == "x-socket-id" }).map { $0.value }
            self?.updateWebSocketID(id)
        }

        socket.onDisconnect = { [weak self] error in
            log(sender: self, "ws client: disconnected, error = \(error.debugDescription)")
            self?.updateWebSocketID(nil)
            self?.onDisconnect?(error)
        }
    }

    func updateWebSocketID(_ uniqueID: String?) {
        authState.wsUniqueID = uniqueID

        if uniqueID == nil {
            log(sender: self, "ws client: ws unique id cleared")
        } else {
            log(sender: self, "ws client: new ws unique id = \(uniqueID ?? "")")
        }
    }

    static func makeWebSocketURLFromBaseURL(url: URL, token: String) -> URL {
        guard let wsURL = URL(
            string: url.absoluteString
                .replacingOccurrences(of: "http://", with: "ws://")
                .replacingOccurrences(of: "https://", with: "wss://")
        ) else {
            assertionFailure("Invalid base URL, using given URL w/o changes")
            return url
        }

        let fullPath = wsURL.appendingPathComponent(endpoint).absoluteString + "?access_token=\(token)"

        guard let completeURL = URL(string: fullPath) else {
            assertionFailure("Invalid URL transform, using given URL w/o changes")
            return url
        }

        return completeURL
    }
}
