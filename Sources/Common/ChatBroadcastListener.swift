import Foundation
import GRDB

/// ChatBroadcastListenerProtocol
public protocol ChatBroadcastListenerProtocol: AutoMockable {

    /// iterates through channels with unfinished sends, 
    /// mark new messages as failed, create a preview, notify listener, and clean up
    func failNonSentMessages()
}

/// Listens to the WebSocket and notifies the app that in it should reload some channels
/// because something has changed there.
/// NB: WebSocket provides us with only channelId to reload.
public final class ChatBroadcastListener {
    private let clientID: String

    public var mayLoadDataForChannel: ((String) -> Bool)?
    public var willLoadDataForChannel: ((String) -> Void)?

    private let webSocketClient: WebSocketClientProtocol
    private let remoteListener: (MessagePreview?) -> Void
    private var chatsToCleanupNotSentMessages: [String: Any] = [:]

    private static var cacheServices = [String: CacheService]()
    private static func cacheService(for clientID: String) -> CacheService {
        guard let cacheService = self.cacheServices[clientID] else {
            let cacheService = CacheService(
                pool: DatabasePool.poolBy(
                    clientID: clientID,
                    cacheDirectory: CacheService.cacheDirectory
                )
            )

            self.cacheServices[clientID] = cacheService
            return cacheService
        }

        return cacheService
    }

    private static func dummySenderDependencies(clientID: String) -> ContentSenderDependencies {
        ContentSenderDependencies(
            sendMessageService: DummySendMessageService(),
            fileService: DummyFileService(),
            cacheService: Self.cacheService(for: clientID)
        )
    }

    private static let contentRendererFactory = ContentRendererFactory()

    private let messageService: MessageServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let dependencies: ContentSenderDependencies

    private var dataSources = [String: MessagesProviderProtocol]()
    private let chatUpdateSemaphore = DispatchSemaphore(value: 5)

    private func dataSourceFor(channelID: String) -> MessagesProviderProtocol {
        if let dataSource = self.dataSources[channelID] {
            return dataSource
        }

        let dataSource = self.messageService.makeMessagesProvider(
            channelID: channelID, messageTypesToIgnore: []
        )
        
        self.dataSources[channelID] = dataSource
        return dataSource
    }

    public init(
        clientAppID: String?,
        chatBaseURL: URL,
        accessToken: String,
        clientID: String,
        contentRenderers: [ContentRenderer.Type] = [],
        remoteListener: @escaping (MessagePreview?) -> Void
    ) {
        self.clientID = clientID
        self.remoteListener = remoteListener

        self.cacheService = Self.cacheService(for: clientID)
        self.dependencies = Self.dummySenderDependencies(clientID: clientID)

        let authState = AuthState(
            accessToken: accessToken,
            clientAppID: clientAppID,
            deviceID: nil,
            wsUniqueID: nil
        )

        self.messageService = Self.makeMessagesRetriever(
            clientID: clientID,
            chatBaseURL: chatBaseURL,
            authState: authState
        )

        let internalPresenters = ChatDependencies.internalPresenters
        let allPresenters = contentRenderers + internalPresenters

        for presenterType in internalPresenters {
            Self.contentRendererFactory.register(presenter: presenterType)
        }

        Message.set(
            messageContentFactory: MessageContentFactory(
                contentTypes: allPresenters.map({
                    $0.messageContentType
                })
            )
        )

        self.webSocketClient = WebSocketClient(baseURL: chatBaseURL, authState: authState)

        self.webSocketClient.onDisconnect = { [weak self] error in
            let errorDescription = error?.localizedDescription ?? ""
            log(
                sender: self,
                "ChatBroadcastListener: received web socket error, trying to reconnect \(errorDescription)"
            )
            let queue = DispatchQueue.global(qos: .default)
            queue.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.webSocketClient.connect()
            }
        }

        self.webSocketClient.onChannelUpdate = { [weak self] channelID in
            guard let self else { return }

            if self.mayLoadDataForChannel?(channelID) == false {
                return
            }

            log(sender: self, "WEBSOCKET UPDATE FOR \(channelID)")
            self.loadDataFor(channelID: channelID)
        }

        self.webSocketClient.connect()
    }
}

// MARK: - IChatBroadcastListener

extension ChatBroadcastListener: ChatBroadcastListenerProtocol {

    public func failNonSentMessages() {
        let channelIDs = ChatPresenter.channelsWithUnfinishedSends.keys

        channelIDs.forEach { channelID in
            let presenter = chatToCleanupNotSentMessages(channelID)

            presenter.messagesProvider.loadInitialMessages { [weak self] _ in
                guard let self = self else { return }
                guard var message = presenter.messages.first else { return }

                if message.status == .new {
                    message = message.copyUpdating(status: .failed)
                }

                if let preview = message.makePreview(
                    clientID: clientID,
                    channelID: channelID,
                    cacheService: cacheService,
                    senderDependencies: dependencies
                ) {
                    remoteListener(preview)
                    ChatPresenter.channelsWithUnfinishedSends[channelID] = nil
                }
            }
        }
    }
}

// MARK: - Private

private extension ChatBroadcastListener {

    func loadDataFor(channelID: String) {
        self.willLoadDataForChannel?(channelID)
        let dataSource = self.dataSourceFor(channelID: channelID)
        dataSource.loadNewerMessages { [weak self] updateData in
            self?.handleMessagesProviderUpdate(updateData, channelID: channelID)
        }
    }

    func chatToCleanupNotSentMessages(_ channelID: String) -> ChatPresenter {
        var presenter: ChatPresenter! = self.chatsToCleanupNotSentMessages[channelID] as? ChatPresenter
        presenter = presenter ?? ChatPresenter(
            clientID: self.clientID,
            channelID: channelID,
            messageService: self.messageService,
            cacheService: self.cacheService,
            contentRendererFactory: Self.contentRendererFactory
        )
        self.chatsToCleanupNotSentMessages[channelID] = presenter
        return presenter
    }

    static func makeMessagesRetriever(
        clientID: String,
        chatBaseURL: URL,
        authState: AuthState
    ) -> MessageServiceProtocol {
        let cacheService = Self.cacheService(for: clientID)
        let messagesClient = MessagesClient(
            baseURL: chatBaseURL,
            authState: authState,
            urlSessionConfiguration: APIClient.urlSessionConfiguration
        )

        let receiveMessageService = MessageService(
            messagesClient: messagesClient,
            webSocketClient: WebSocketClient(baseURL: chatBaseURL, authState: authState),
            messagesCacheService: cacheService
        )

        return receiveMessageService
    }

    func handleMessagesProviderUpdate(_ data: MessagesProviderCallbackData, channelID: String) {
        if data.isFromCache {
            return
        }

        if data.error != nil {
            self.remoteListener(nil)
            return
        }

        let previews = data.messages.compactMap { message in
            message.makePreview(
                clientID: clientID,
                channelID: channelID,
                cacheService: self.cacheService,
                senderDependencies: self.dependencies
            )
        }

        let preview = previews.first

        self.remoteListener(preview)
    }
}

// MARK: - enum ChatDependencies

enum ChatDependencies {

    typealias PresenterFactory = (MessageContent, ContentMeta) -> ContentRenderer

    static let dummyContentRendererFactory: ContentRendererFactory = {
        let factory = ContentRendererFactory()

        for presenterType in internalPresenters {
            factory.register(presenter: presenterType)
        }

        return factory
    }()

    static let internalPresenters: [ContentRenderer.Type] = [
        TextContentRenderer.self,
        ImageContentRenderer.self,
        VoiceMessageContentRenderer.self,
        ContactContentRenderer.self,
        LocationContentRenderer.self,
        VideoContentRenderer.self,
        DocumentContentRenderer.self
    ]

    static let internalContentSenders: [ContentSender.Type] = [
        TextContentSender.self,
        ImageContentSender.self,
        VideoContentSender.self,
        ContactContentSender.self,
        DocumentContentSender.self,
        LocationContentSender.self,
        VoiceMessageContentSender.self
    ]

    static var dummyPresenterFactory: PresenterFactory {
        { messageContent, contentMeta in
            dummyContentRendererFactory.make(
                for: messageContent,
                contentMeta: contentMeta,
                actions: ContentRendererActions(),
                dependencies: ContentRendererDependencies(
                    chatDelegate: nil,
                    cacheService: DummyCacheService(),
                    fileService: DummyFileService(),
                    locationService: DummyLocationService(),
                    voiceMessageService: DummyVoiceMessageService()
                )
            )
        }
    }
}
