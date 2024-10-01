import Foundation

extension Notification.Name {
    static let messageServiceDidReceiveChannelUpdate: Self = .init(rawValue: "messageServiceDidReceiveChannelUpdate")
}

// MARK: - MessageServiceProtocol

protocol RecieveMessageServiceProtocol {
    func makeMessagesProvider(channelID: String, messageTypesToIgnore: [MessageType]) -> MessagesProviderProtocol
}

// MARK: - SendMessageServiceProtocol

protocol SendMessageServiceProtocol: AutoMockable {
    // swiftlint:disable:next function_parameter_count
    func send(
        guid: String,
        channelID: String,
        content: MessageContent,
        contentMeta: ContentMeta?,
        replyTo: String?,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    )
}

// MARK: - UpdateMessageServiceProtocol
/// Service to mark messages as read
protocol UpdateMessageServiceProtocol {
    func update(guids: [String], status: MessageStatus, completion: @escaping (Result<Void, Swift.Error>) -> Void)
}

protocol MessageServiceProtocol: RecieveMessageServiceProtocol,
                                 SendMessageServiceProtocol,
                                 UpdateMessageServiceProtocol,
                                 AutoMockable {}

// MARK: - MessageService

final class MessageService: MessageServiceProtocol {
    private static let webSocketReconnectInterval: TimeInterval = 5.0

    private let messagesClient: MessagesClientProtocol
    private let webSocketClient: WebSocketClientProtocol
    private let messagesCacheService: MessagesCacheServiceProtocol

    init(
        messagesClient: MessagesClientProtocol,
        webSocketClient: WebSocketClientProtocol,
        messagesCacheService: MessagesCacheServiceProtocol
    ) {
        self.messagesClient = messagesClient
        self.webSocketClient = webSocketClient
        self.messagesCacheService = messagesCacheService

        self.setupWebSocketListening()
    }

    func makeMessagesProvider(channelID: String, messageTypesToIgnore: [MessageType]) -> MessagesProviderProtocol {
        let dataSource = MessagesProvider(
            channelID: channelID,
            messagesClient: self.messagesClient,
            messagesCacheService: self.messagesCacheService,
            messageTypesToIgnore: messageTypesToIgnore
        )

        if !self.webSocketClient.isConnected {
            self.webSocketClient.connect()
        }

        return dataSource
    }

    // MARK: - Private

    private func setupWebSocketListening() {
        self.webSocketClient.onDisconnect = { [weak self] error in
            let errorDescription = error?.localizedDescription ?? ""
            log(
                sender: self,
                "ChatBroadcastListener: received web socket error, trying to reconnect \(errorDescription)"
            )

            let queue = DispatchQueue.global(qos: .default)
            queue.asyncAfter(deadline: .now() + Self.webSocketReconnectInterval) { [weak self] in
                self?.webSocketClient.connect()
            }
        }

        self.webSocketClient.onChannelUpdate = { channelID in
            NotificationCenter.default.post(
                name: .messageServiceDidReceiveChannelUpdate,
                object: nil,
                userInfo: ["channelID": channelID]
            )
        }
    }
}

extension MessageService {

    // swiftlint:disable:next function_parameter_count
    func send(
        guid: String,
        channelID: String,
        content: MessageContent,
        contentMeta: ContentMeta?,
        replyTo: String?,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {
        self.sendInternal(
            guid: guid,
            channelID: channelID,
            content: content,
            contentMeta: contentMeta,
            replyTo: replyTo,
            completion: completion
        )
    }

    // MARK: - Private

    private func sendInternal(
        guid: String,
        channelID: String,
        content: MessageContent,
        contentMeta: ContentMeta? = nil,
        replyTo: String? = nil,
        completion: @escaping (Result<Void, Swift.Error>) -> Void
    ) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let message = Message(
            guid: guid,
            channelID: channelID,
            hostingChannelIDs: [channelID],
            timestamp: timestamp,
            source: .chat,
            status: .new,
            content: content,
            contentMeta: contentMeta,
            replyToID: replyTo
        )

        do {
            _ = try self.messagesClient.create(message: message, time: timestamp) { result in
                switch result {
                case .success(let response):
                    if 200...299 ~= response.httpStatusCode {
                        completion(.success(()))
                    } else {
                        completion(.failure(Error.serverError(code: response.httpStatusCode)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) sendInternal",
                "details": "\(#function) sendingFailed",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            completion(.failure(Error.sendingFailed))
        }
    }

    // MARK: - Error

    enum Error: Swift.Error {
        case sendingFailed
        case updatingFailed
        case serverError(code: Int)
    }
}

extension MessageService {
    func update(guids: [String], status: MessageStatus, completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        do {
            _ = try self.messagesClient.update(guids: guids, status: status) { result in
                switch result {
                case .success(let response):
                    if 200...299 ~= response.httpStatusCode {
                        completion(.success(()))
                    } else {
                        completion(.failure(Error.serverError(code: response.httpStatusCode)))
                    }
                case .failure(let error):
                    completion(.failure(error))

                    let userInfo: [String: Any] = [
                        "sender": "\(type(of: self)) \(#function)",
                        "details": "updatingFailed",
                        "error": error
                    ]
                    NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
                }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "updatingFailed",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            completion(.failure(Error.updatingFailed))
        }
    }
}

// To use dependencies containing SendMessageServiceProtocol without instance
final class DummySendMessageService: SendMessageServiceProtocol {
    init() { }

    // swiftlint:disable:next function_parameter_count
    func send(
        guid: String,
        channelID: String,
        content: MessageContent,
        contentMeta: ContentMeta?,
        replyTo: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) { }
}
