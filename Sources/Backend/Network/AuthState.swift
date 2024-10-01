import Foundation

extension Notification.Name {
    static let didRefreshToken = Notification.Name("didRefreshToken")
}

// MARK: - Auth data

public protocol AuthStateProtocol: AnyObject, AutoMockable {
    var accessToken: String? { get set }
    var clientAppID: String? { get set }
    var deviceID: String? { get set }
    var wsUniqueID: String? { get set }
    var bearerToken: String? { get }

    init(accessToken: String?, clientAppID: String?, deviceID: String?, wsUniqueID: String?)
}

public final class AuthState: AuthStateProtocol {
    /// User access token
    public var accessToken: String?
    /// Unique client (application) ID
    public var clientAppID: String?
    /// Unique device ID
    public var deviceID: String?
    /// WebSocket unique ID
    public var wsUniqueID: String?

    public var bearerToken: String? {
        accessToken.flatMap { "\($0)" }
    }

    public init(accessToken: String?, clientAppID: String?, deviceID: String?, wsUniqueID: String?) {
        self.accessToken = accessToken
        self.clientAppID = clientAppID
        self.deviceID = deviceID
        self.wsUniqueID = wsUniqueID

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didRefreshToken(_:)),
            name: .didRefreshToken,
            object: nil
        )
    }
}

// MARK: - private

private extension AuthState {

    @objc
    func didRefreshToken(_ notification: Notification) {
        guard let accessToken = notification.userInfo?["access_token"] as? String else {
            return
        }

        self.accessToken = accessToken
    }
}
