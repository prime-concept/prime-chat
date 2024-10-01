import Foundation
import GRDB

typealias FeatureFlags = Configuration.FeatureFlags

/// Global object for Chat SDK
public final class Assembly {
    // MARK: - Private properties

    private let clientID: String
    private let featureFlags: FeatureFlags

    private let messagesClient: MessagesClientProtocol
    private let webSocketClient: WebSocketClientProtocol

    private let messageService: MessageServiceProtocol

    private let voiceMessageService: VoiceMessageServiceProtocol
    private let fileService: FileServiceProtocol
    private let contactsService: ContactsServiceProtocol
    private let locationService: LocationServiceProtocol
    private let cacheService: CacheServiceProtocol

    private let contentRendererFactory: ContentRendererFactory
    private let pickerModuleFactory: PickerModuleFactory

    // MARK: - Methods

    /// Create entry-point object for Chat SDK
    /// - Parameters:
    ///     - configuration: Configuration
    ///     - accessToken: Authorization token
    public init(clientID: String, accessToken: String, configuration: Configuration) {
        // Start network monitor
        _ = NetworkMonitor.shared

        // Logging
        MAY_LOG_IN_PRINT = configuration.shouldEnableLogging

        // Feature flags
        self.featureFlags = configuration.featureFlags

        // Global auth state
        let authState = AuthState(
            accessToken: accessToken,
            clientAppID: configuration.clientAppID,
            deviceID: nil,
            wsUniqueID: nil
        )

        // Internal presentation adapters
        let internalPresenters = ChatDependencies.internalPresenters

        let contentRendererFactory = ContentRendererFactory()
        let allPresenters = configuration.contentRenderers + internalPresenters
        for presenterType in allPresenters {
            contentRendererFactory.register(presenter: presenterType)
        }

        // Content senders
        let internalContentSenders = ChatDependencies.internalContentSenders
        let allContentSenders = configuration.contentSenders + internalContentSenders

        // Register types for decoding
        Message.set(
            messageContentFactory: MessageContentFactory(contentTypes: allPresenters.map {
                $0.messageContentType
            })
        )

        // Cache
        let cacheService = CacheService(
            pool: DatabasePool.poolBy(
                clientID: clientID,
                cacheDirectory: CacheService.cacheDirectory
            )
        )


        // Register types for draft caches
        MessageDraft.set(contentSenders: allContentSenders)

        // Messages client
        let messagesClient = MessagesClient(
            baseURL: configuration.chatBaseURL,
            authState: authState,
            urlSessionConfiguration: APIClient.urlSessionConfiguration
        )

        // WS
        let webSocketClient = WebSocketClient(baseURL: configuration.chatBaseURL, authState: authState)

        // Record and play voice messages
        let voiceMessageService = VoiceMessageService()
        voiceMessageService.storageBaseURL = configuration.storageBaseURL
        voiceMessageService.authState = authState

        // Play video
        let videoMessageService = VideoMessageService.shared
        videoMessageService.storageBaseURL = configuration.storageBaseURL
        videoMessageService.authState = authState

        // Fetch contacts
        let contactsService = ContactsService()

        // Fetch location
        let locationService = LocationService()

        // Upload files
        let fileStorageClient = FileStorageClient(
            baseURL: configuration.storageBaseURL,
            authState: authState,
            urlSessionConfiguration: APIClient.urlSessionConfiguration
        )
        let fileService = FileService(storageClient: fileStorageClient, filesCacheService: cacheService)

        // Pickers
        let pickerModuleFactory = PickerModuleFactory()
        pickerModuleFactory.register(picker: DefaultDocumentPickerModule.self, for: DocumentContent.self)
        pickerModuleFactory.register(picker: DefaultMediaAssetPickerModule.self, for: ImageContent.self)
        pickerModuleFactory.register(picker: DefaultCameraPickerModule.self, for: ImageContent.self)
        pickerModuleFactory.register(picker: DefaultContactPickerModule.self, for: ContactContent.self)
        pickerModuleFactory.register(picker: DefaultLocationPickerModule.self, for: LocationContent.self)
        
        for (messageContent, externalPicker) in configuration.pickerModules {
            pickerModuleFactory.register(picker: externalPicker, for: messageContent)
        }

        // Retrieve message service
        let messageService = MessageService(
            messagesClient: messagesClient,
            webSocketClient: webSocketClient,
            messagesCacheService: cacheService
        )

        // Store props
        self.messagesClient = messagesClient
        self.messageService = messageService
        self.webSocketClient = webSocketClient
        self.contentRendererFactory = contentRendererFactory
        self.voiceMessageService = voiceMessageService
        self.fileService = fileService
        self.contactsService = contactsService
        self.locationService = locationService
        self.clientID = clientID
        self.pickerModuleFactory = pickerModuleFactory
        self.cacheService = cacheService

        // Set theme
        self.updateTheme(configuration.initialTheme)
    }

    /// Update current theme
    public func updateTheme(_ theme: Theme) {
        ThemeProvider.current = theme
    }

    /// Create module for channel
    public func makeChatViewController(
        channelID id: String,
        chatDelegate: ChatDelegateProtocol?,
        messageTypesToIgnore: [MessageType],
        preinstalledText: String? = nil,
        messageGuidToOpen: String? = nil
    ) -> ChatViewController {
        return ChatAssembly.make(
            channelID: id,
            clientID: self.clientID,
            featureFlags: self.featureFlags,
            moduleDelegate: chatDelegate,
            messageService: self.messageService,
            contentRendererFactory: self.contentRendererFactory,
            pickerModuleFactory: self.pickerModuleFactory,
            voiceMessageService: self.voiceMessageService,
            fileService: self.fileService,
            cacheService: self.cacheService,
            contactsService: self.contactsService,
            locationService: self.locationService,
            messageTypesToIgnore: messageTypesToIgnore,
            preinstalledText: preinstalledText,
            messageGuidToOpen: messageGuidToOpen
        )
    }
}
