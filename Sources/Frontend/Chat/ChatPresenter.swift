import UIKit

protocol ChatPresenterProtocol: AnyObject, AutoMockable {
    var shouldShowSafeAreaView: Bool { get }
    var bottomViewExists: Bool { get }
    func retryMessageSending(message: Message)
    func retryMessageSending(guid: String)
    func loadInitialMessages()
    func didAppear()

    func sendMessage(sender: ContentSender, completion: ((Bool) -> Void)?)
    func sendMessage(_ message: Message?, sender: ContentSender, completion: ((Bool) -> Void)?)
    func saveDraft(
        messageGUID: String,
        messageStatus: MessageStatus,
        text: String,
        attachments: [ContentSender]
    )
}

// swiftlint:disable type_body_length
final class ChatPresenter: ChatPresenterProtocol {
    private let channelID: String
    private let clientID: String

    private let messageService: MessageServiceProtocol
    private let fileService: FileServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let voiceMessageService: VoiceMessageServiceProtocol
    private let locationService: LocationServiceProtocol

    private lazy var senderDependencies = ContentSenderDependencies(
        sendMessageService: self.messageService,
        fileService: self.fileService,
        cacheService: self.cacheService
    )

    private lazy var presentationDependencies = ContentRendererDependencies(
        chatDelegate: self.moduleDelegate,
        cacheService: self.cacheService,
        fileService: self.fileService,
        locationService: self.locationService,
        voiceMessageService: self.voiceMessageService
    )

    weak var messagesListViewController: MessagesList?
    weak var messageInputViewController: MessageInput?

    var moduleDelegate: ChatDelegateProtocol?
    let messagesProvider: MessagesProviderProtocol

    private let contentRendererFactory: ContentRendererFactory
    private let featureFlags: FeatureFlags

    private var isDataLoaded = false

    @ThreadSafe
    private var mayLoadOlderMessages = true

    @ThreadSafe
    private var mayLoadNewerMessages = true

    @ThreadSafe
    private var unseenMessageItemIDToMessages: [String: Message] = [:]

    private lazy var updatesQueue = DispatchQueue(label: "\(Self.self).updatesQueue", qos: .userInitiated)
    private lazy var loadingQueue = DispatchQueue(label: "\(Self.self).loadingQueue", qos: .userInitiated)

    /**
     Спрашивается, почему статик? А чтобы можно было отправить большой файл, закрыть чат, и чтобы
     посылалка не померла.
     */
    @ThreadSafe
    private static var messagesBeingSent: [String: (message: Message, sender: ContentSender)] = [:]

    var shouldShowSafeAreaView: Bool {
        return self.moduleDelegate?.shouldShowSafeAreaView ?? true
    }
    
    var bottomViewExists: Bool {
        self.messagesListViewController?.bottomViewExists ?? false
    }

    private let messageTypesToIgnore: [MessageType]
    private var preinstalledText: String?

    init(
        clientID: String,
        channelID: String,
        featureFlags: FeatureFlags = .all(),
        messageService: MessageServiceProtocol,
        fileService: FileServiceProtocol = DummyFileService(),
        cacheService: CacheServiceProtocol = DummyCacheService(),
        locationService: LocationServiceProtocol = DummyLocationService(),
        voiceMessageService: VoiceMessageServiceProtocol = DummyVoiceMessageService(),
        contentRendererFactory: ContentRendererFactory,
        messageTypesToIgnore: [MessageType] = [.taskLink],
        preinstalledText: String? = nil
    ) {
        self.clientID = clientID
        self.channelID = channelID
        self.featureFlags = featureFlags
        self.messageService = messageService
        self.fileService = fileService
        self.cacheService = cacheService
        self.locationService = locationService
        self.voiceMessageService = voiceMessageService
        self.contentRendererFactory = contentRendererFactory
        self.messageTypesToIgnore = messageTypesToIgnore
        self.preinstalledText = preinstalledText
        self.messagesProvider = messageService.makeMessagesProvider(
            channelID: channelID, messageTypesToIgnore: messageTypesToIgnore
        )

        self.subscribeToNotifications()
    }

    deinit {
        self.moduleDelegate?.didChatControllerStatusUpdate(with: .unload)

        log(sender: self, "\(Self.self) WILL DEINIT. HAVE MESSAGES TO MAKE SEEN: \(self.guidsToMarkAsSeen)")
    }

    // MARK: - Public

    func loadInitialMessages() {
        self.loadingQueue.async {
            guard self.mayLoadOlderMessages, self.mayLoadNewerMessages else {
                return
            }

            self.mayLoadOlderMessages = false
            self.mayLoadNewerMessages = false

            self.moduleDelegate?.didChatControllerStatusUpdate(with: .load)

            self.messagesProvider.loadInitialMessages { [weak self] data in
                self?.handleMessagesProviderUpdate(data)
            }
        }
    }

    func didAppear() {
        self.preinstalledText.flatMap { text in
            self.messageInputViewController?.set(message: text)
            self.preinstalledText = nil
        }
    }

    // MARK: - Private

    private func handleMessagesProviderUpdate(_ data: MessagesProviderCallbackData) {
        self.updatesQueue.async {
            self.messagesData = data

            self.failNotSentMessagesFromPreviousLaunch()

            self.isDataLoaded = true

            if !data.isFromCache {
                self.moduleDelegate?.didLoadInitialMessages()
            }

            self.allowLoading(by: data)

            self.generateViewModelsAndUpdate(with: data)

            guard let error = data.error else { return }

            self.retryLoading(for: data)

            NotificationCenter.default.post(
                name: .chatNetworkErrorNotification,
                object: nil,
                userInfo: ["error": error]
            )
        }
    }

    private var messagesData = MessagesProviderCallbackData(
        messages: [],
        direction: nil,
        isFromCache: false,
        hasOlderMessages: true
    )
    
    var messages: [Message] {
        self.messagesData.messages
    }

    private func subscribeToNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(messageServiceDidReceiveChannelUpdate(_:)),
            name: .messageServiceDidReceiveChannelUpdate,
            object: nil
        )
    }

    @objc
    private func messageServiceDidReceiveChannelUpdate(_ notification: Notification) {
        guard let channelID = notification.userInfo?["channelID"] as? String,
              channelID == self.channelID else {
            return
        }

        self.messagesProvider.loadNewerMessages { [weak self] data in
            self?.handleMessagesProviderUpdate(data)
        }
    }

    private func generateViewModelsAndUpdate(with data: MessagesProviderCallbackData) {
        let allMessages = self.allMessages(with: data.messages)

        var items: [MessagesListItemModelProtocol] = []
        var lastDate: String?

        self.unseenMessageItemIDToMessages.removeAll(keepingCapacity: true)

        for (index, message) in allMessages.enumerated() {
            guard let content = message.content else {
                log(sender: self, "ERROR: Message should contain non-empty content \(message.guid)")
                continue
            }

            let isNextMessageOfSameUser = message.clientID == allMessages[safe: index - 1]?.clientID

            // Insert time separator
            let messageDate = Date(timeIntervalSince1970: Double(message.timestamp))
            let formattedDate = Calendar.current.isDateInToday(messageDate)
            ? Self.dateSeparatorRelativeFormatter.string(from: messageDate)
            : Self.dateSeparatorFormatter.string(from: messageDate)
            let replyDuringSending = self.sender(for: message)?.replyPreview
            let meta = self.makeMessageContainerModelMeta(
                from: message,
                date: formattedDate,
                currentClientID: self.clientID,
                replyDuringSending: replyDuringSending,
                isFailed: message.status == .failed,
                isNextMessageOfSameUser: isNextMessageOfSameUser
            )

            if let lastDate = lastDate, lastDate != formattedDate {
                let item = TimeSeparatorModel(
                    uid: "TimeSeparator_\(lastDate)",
                    date: lastDate
                )
                items.append(item)
            }
            lastDate = formattedDate

            let actions = ContentRendererActions(
                onRetry: { [weak self, message] in
                    self?.retryMessageSending(message: message)
                },
                onReply: { [weak self, message] in
                    self?.replyOnMessage(message)
                },
                onLongPress: { [weak self, message] in
                    self?.shareMessage(message)
                }
            )

            let sender = Self.messagesBeingSent[message.guid]?.sender

            var contentToDisplay = sender?.content ?? content
            contentToDisplay.messageGUID = message.guid

            let displayAdapter = self.contentRendererFactory.make(
                for: contentToDisplay,
                contentMeta: message.contentMeta,
                actions: actions,
                dependencies: self.presentationDependencies
            )

            let messageItemID = "Message_\(message.guid)"
            if meta.status == .unseen, meta.author != .me {
                self.unseenMessageItemIDToMessages[messageItemID] = message
            }

            let itemToDisplay = displayAdapter.messageModel(with: messageItemID, meta: meta)
            items.append(itemToDisplay)
        }

        if let lastDate = lastDate {
            let item = TimeSeparatorModel(
                uid: "TimeSeparator_\(lastDate)",
                date: lastDate
            )
            items.append(item)
        }

        if data.isLoading {
            log(sender: self, "WILL SHOW LOADING INDICATOR")
            items.append(LoadingIndicatorModel())
        } else {
            log(sender: self, "WILL SKIP LOADING INDICATOR")
        }

        DispatchQueue.main.async {
            self.messagesListViewController?.update(with: items)
        }
    }

    private func allowLoading(by data: MessagesProviderCallbackData) {
        self.loadingQueue.async {
            if data.isLoading { return }

            if data.direction == .newer {
                self.mayLoadNewerMessages = true
                return
            }

            if data.direction == .older {
                self.mayLoadOlderMessages = true
            }
        }
    }

    private func retryLoading(for data: MessagesProviderCallbackData) {
        self.loadingQueue.asyncAfter(deadline: .now() + 1) {
            if data.direction == .newer {
                self.loadNewerMessages()
            }

            if data.direction == .older {
                self.loadOlderMessages()
            }
        }
    }
    
    private func allMessages(with messages: [Message]) -> [Message] {
        let drafts = self.cacheService.retrieveDrafts(channelID: self.channelID)

        let messages: [Message] = messages.compactMap { (message: Message) -> Message? in
            let type = message.content?.messageType
            if let type = type, self.messageTypesToIgnore.contains(type) || message.status == .deleted {
                return nil
            }

            let draft = drafts.first { $0.messageGUID == message.guid }
            let draftSender = draft?.getSendersForAttachments(with: self.senderDependencies).first
            let draftContent = draftSender?.content

            if let content = draftContent {
                return message.copyUpdating(content: content)
            }

            return message
        }

        return messages
    }

    // swiftlint:disable:next function_parameter_count
    private func makeMessageContainerModelMeta(
        from message: Message,
        date: String,
        currentClientID: String,
        replyDuringSending: ReplyPreview?,
        isFailed: Bool,
        isNextMessageOfSameUser: Bool
    ) -> MessageContainerModelMeta {
        let messageStatus: MessageContainerModelMeta.Status = {
            if isFailed {
                return .failed
            }
            switch message.status {
            case .seen:
                return self.featureFlags.contains(.canReadReceipts) ? .seen : .unseen
            case .new:
                return .sending
            default:
                return .unseen
            }
        }()

        let messageAuthor: MessageContainerModelMeta.Author = {
            message.clientID == currentClientID ? .me : .anotherUser
        }()

        let messageTime = Self.messageTimeFormatter.string(from: Date(timeIntervalSince1970: Double(message.timestamp)))

        let replyMeta = message.replyTo?.first.flatMap {
            let isMe = $0.clientID == self.clientID
            let senderName = isMe ? ($0.senderName ?? "sender".localized)
                                  : "assistant".localized

            return MessageReplyModelMeta(
                senderName: senderName,
                content: $0.content?.replyPreview ?? ""
            )
        }

        let replyDuringSending = replyDuringSending.flatMap {
            return MessageReplyModelMeta(
                senderName: $0.sender,
                content: $0.reply
            )
        }

        return MessageContainerModelMeta(
            time: messageTime,
            date: date,
            status: messageStatus,
            messenger: message.source,
            author: messageAuthor,
            isNextMessageOfSameUser: isNextMessageOfSameUser,
            replyMeta: replyMeta ?? replyDuringSending
        )
    }

    @ThreadSafe
    private var guidsToMarkAsSeen = Set<String>()
    private lazy var markAsSeenThrottler = Throttler(timeout: 0.3, executesPendingAfterCooldown: true) { [weak self] in
        guard let self = self else { return }
        if self.guidsToMarkAsSeen.isEmpty { return }

        let guids = self.guidsToMarkAsSeen
        self.guidsToMarkAsSeen.removeAll()

        self.messageService.update(guids: Array(guids), status: .seen) { [weak self] result in
            guard let self = self else { return }
            guard case .success = result else {
                guids.forEach { self.guidsToMarkAsSeen.insert($0) }
                return
            }

            let messages = guids.compactMap { guid in
                self.unseenMessageItemIDToMessages[guid] = nil
                var message = self.unseenMessageItemIDToMessages["Message_\(guid)"]
                message?.status = .seen
                return message
            }
            
            self.cacheService.save(messages: messages)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    .messagesProviderDisplayableMessagesChanged,
                    userInfo: ["messages": messages]
                )
            }
        }
    }

    private func markMessageItemSeenIfNeeded(guid: String) {
        self.guidsToMarkAsSeen.insert(guid)
        self.markAsSeenThrottler.execute()
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func shareMessage(_ message: Message) {
        guard let content = message.content else {
            return
        }

        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()
        feedbackGenerator.selectionChanged()

        switch content.messageType {
        case .text:
            guard let text = (content as? TextContent)?.string else { return }
            Sharing.manager.share(text: text)
        case .image:
            guard let path = (content as? ImageContent)?.content.path,
                  let fileInfo = FileInfo(remotePath: path) else {
                return
            }
            self.fileService.download(
                file: fileInfo,
                skipCache: false) { data in
                    DispatchQueue.main.async {
                        if let data = data {
                            Sharing.manager.share(imageData: data)
                        }
                    }
                }
        case .voiceMessage:
            guard let content = (content as? VoiceMessageContent)?.content,
                  case let .remote(file: file) = content else {
                return
            }
            self.fileService.download(
                file: file,
                skipCache: false) { data in
                    DispatchQueue.main.async {
                        if let data = data {
                            Sharing.manager.share(audioData: data)
                        }
                    }
                }
        case .video:
            guard let path = (content as? VideoContent)?.content.path,
                  let fileInfo = FileInfo(remotePath: path),
                  let dataCached: Data = self.cacheService.retrieve(file: fileInfo) else {
                return
            }
            Sharing.manager.share(videoData: dataCached)
        case .location:
            guard let content = (content as? LocationContent)?.content else {
                return
            }
            guard case .remote(let path) = content,
                  let file = FileInfo(remotePath: path) else {
                return
            }
            self.fileService.downloadAndDecode(
                file: file,
                skipCache: false,
                onMainQueue: false
            ) { (locationWrapper: StorageLocationWrapper?) in
                if let locationWrapper = locationWrapper {
                    Sharing.manager.share(latitude: locationWrapper.latitude, longitude: locationWrapper.longitude)
                }
            }
        case .contact:
            if let content = (content as? ContactContent)?.content {
                guard case .remote(let path) = content,
                      let file = FileInfo(remotePath: path) else {
                    return
                }
                self.fileService.downloadAndDecode(
                    file: file,
                    skipCache: false,
                    onMainQueue: false
                ) { (contact: ContactItem?) in
                    Sharing.manager.share(contact: contact?.contact)
                }
            }
        case .doc:
            if let path = (content as? DocumentContent)?.content.path,
               let fileInfo = FileInfo(remotePath: path) {
                self.fileService.download(
                    file: fileInfo,
                    skipCache: false) { data in
                        DispatchQueue.main.async {
                            Sharing.manager.share(data: data)
                        }
                    }
            }
        default:
            log(sender: self, content.messageType)
        }
    }

    private func failNotSentMessagesFromPreviousLaunch() {
        let sendingMessageIDs = Self.messagesBeingSent.keys

        let danglingUnsentMessages = self.messagesData.messages.filter { message in
            message.status == .new && !sendingMessageIDs.contains(message.guid)
        }

        danglingUnsentMessages.forEach { message in
            self.sender(for: message).flatMap { sender in
                failMessage(message, sender: sender)
            }
        }
    }

    private func failMessage(_ message: Message, sender: ContentSender) {
        let timestamp = Int(Date().timeIntervalSince1970)

        let message = message
            .copyUpdating(status: .failed)
            .copyUpdating(updatedAt: timestamp)

        self.messagesData = self.messagesProvider.saveMessage(message)

        self.removeDraft(messageGUID: message.guid)
        self.saveAsDraft(message, sender: sender)

        if let delegate = self.moduleDelegate, let preview = self.makePreview(from: message) {
            delegate.didMessageSendingStatusUpdate(with: .error, preview: preview)
        }
    }

    private func failDraft(_ draft: MessageDraft) {
        var draft = draft
        draft.messageStatus = .failed

        self.removeDraft(messageGUID: draft.messageGUID)
        self.cacheService.save(draft: draft)

        let preview = draft.makePreview(with: self.senderDependencies)
        self.moduleDelegate?.didMessageSendingStatusUpdate(with: .error, preview: preview)
    }
}
// swiftlint:enable type_body_length

// MARK: - MessagesListDelegateProtocol

extension ChatPresenter: MessagesListDelegateProtocol {
    func willDisplayItem(uid: UniqueIdentifierType) {
        self.unseenMessageItemIDToMessages[uid].flatMap {
            self.markMessageItemSeenIfNeeded(guid: $0.guid)
        }
    }

    /*
     Это почти конец пути изнурительного прокидывания.
     Сейчас мы дернем loadOlder/NewerMessages у MessagesProvider-а, вот в нем-то и происходит
     настоящая загрузка сообщений.

     У MessagesProvider-а сработает колбэк и цепочка начнет раскручиваться в обратном порядке:

     ChatPresenter (этот файл) дернет метод update... у MessagesListController-a
     Контроллер - update... у MessageListPresenter-а
     Презентер - update... у контроллера MessagesListViewController
     Контроллер - update... у датасурса MessagesListDataSource,
     где уже отрелоудится collectionView.
     */
    func loadOlderMessages() {
        self.loadingQueue.async {
            guard self.mayLoadOlderMessages else {
                return
            }

            log(sender: self, "chat presenter: request OLDER items")
            self.mayLoadOlderMessages = false

            self.messagesProvider.loadOlderMessages { [weak self] data in
                self?.handleMessagesProviderUpdate(data)
            }
        }
    }
    
    func loadNewerMessages() {
        self.loadingQueue.async {
            guard self.mayLoadNewerMessages else {
                return
            }

            log(sender: self, "chat presenter: request NEWER items")
            self.mayLoadNewerMessages = false

            self.messagesProvider.loadNewerMessages { [weak self] data in
                self?.handleMessagesProviderUpdate(data)
            }
        }
    }

    func retryMessageSending(guid: String) {
        let message = self.messagesData.messages.first { $0.guid == guid }

        guard let message else {
            return
        }

        self.retryMessageSending(message: message)
    }

    func retryMessageSending(message: Message) {
        guard let sender = self.sender(for: message) else {
            return
        }
        self.removeFailedMessage(message)
        let newMessage = message.copyUpdating(status: .new)
        self.sendMessage(newMessage, sender: sender)
    }

    private func sender(for message: Message) -> ContentSender? {
        if let sender = Self.messagesBeingSent[message.guid]?.sender {
            return sender
        }

        let draft = self.cacheService
            .retrieveDraft(
                channelID: self.channelID,
                messageGUID: message.guid
            )

        guard let draft = draft else {
            return nil
        }

        let sender = draft.getSendersForAttachments(with: self.senderDependencies).first
        return sender
    }

    private func removeFailedMessage(_ message: Message) {
        self.messagesData = self.messagesProvider.deleteMessage(message)
    }

    func replyOnMessage(_ message: Message) {
        guard let replyPreview = message.content?.replyPreview else {
            return
        }

        let isMe = message.clientID == self.clientID
        let senderName = isMe ? message.senderName ?? "sender".localized
        : "assistant".localized
        let model = ReplyPreview(
            guid: message.guid,
            reply: replyPreview,
            sender: senderName
        )
        self.messageInputViewController?.attach(reply: model)
    }
}

// MARK: - MessageInputDelegateProtocol

extension ChatPresenter: MessageInputDelegateProtocol {
    func sendMessage(sender: ContentSender, completion: ((Bool) -> Void)?) {
        self.sendMessage(nil, sender: sender, completion: completion)
    }

    func sendMessage(_ message: Message?, sender: ContentSender, completion: ((Bool) -> Void)? = nil) {
        let guid = sender.messageGUID
        let timestamp = Int(Date().timeIntervalSince1970)
        let message = message?
            .copyUpdating(timestamp: timestamp)
            .copyUpdating(updatedAt: timestamp)

        var messageToReply: Message?
        if let replyID = sender.replyPreview?.guid {
            messageToReply = self.messagesData.messages.first { $0.guid == replyID }
        }

        var newMessage: Message = message ?? Message(
            guid: guid,
            clientID: self.clientID,
            channelID: self.channelID,
            hostingChannelIDs: [self.channelID],
            timestamp: timestamp,
            status: .new,
            content: sender.content,
            replyToID: messageToReply?.guid,
            replyTo: [messageToReply].compactMap { $0 }
        )

        if let guid = message?.guid {
            self.removeDraft(messageGUID: guid)
        }
        self.removeDraft(messageGUID: guid)
        self.saveAsDraft(newMessage, sender: sender)
        Self.messagesBeingSent[guid] = (newMessage, sender)

        self.messagesData = self.messagesProvider.saveMessage(newMessage)

        self.generateViewModelsAndUpdate(with: self.messagesData)

        if let preview = self.makePreview(from: newMessage) {
            self.moduleDelegate?.didMessageSendingStatusUpdate(with: .inProgress, preview: preview)
        }

        let onProgressDuringSending: (MessageContent, ContentMeta) -> Void = { updatedContentType, contentMeta in
            newMessage = newMessage
                .copyUpdating(content: updatedContentType)
                .copyUpdating(contentMeta: contentMeta)

            self.messagesData = self.messagesProvider.saveMessage(newMessage)

            self.removeDraft(messageGUID: newMessage.guid)
            self.saveAsDraft(newMessage, sender: sender)

            if let preview = self.makePreview(from: newMessage) {
                self.moduleDelegate?.didMessageSendingStatusUpdate(with: .inProgress, preview: preview)
            }

            self.generateViewModelsAndUpdate(with: self.messagesData)
        }

        let onCompletion: (Result<MessageContent, Error>) -> Void = { result in
            defer {
                self.generateViewModelsAndUpdate(with: self.messagesData)
                Self.messagesBeingSent[guid] = nil
                self.persistSendFinished()
            }

            switch result {
            case .failure:
                defer { completion?(false) }
                self.failMessage(newMessage, sender: sender)
            case .success(let content):
                defer { completion?(true) }
                newMessage = newMessage
                    .copyUpdating(content: content)
                    .copyUpdating(status: .sent)

                self.messagesData = self.messagesProvider.saveMessage(newMessage)

                if let preview = self.makePreview(from: newMessage) {
                    self.moduleDelegate?.didMessageSendingStatusUpdate(with: .success, preview: preview)
                }

                self.removeDraft(messageGUID: newMessage.guid)
                self.messagesProvider.loadNewerMessages { [weak self] data in
                    self?.handleMessagesProviderUpdate(data)
                }
            }
        }

        self.persistSendStarted()

        sender.send(
            channelID: self.channelID,
            using: self.senderDependencies,
            updates: onProgressDuringSending,
            completion: onCompletion
        )
    }

    func present(controller: UIViewController) {
        self.moduleDelegate?.requestPresentation(for: controller, completion: nil)
    }

    func didTextViewEditingStatusUpdate(with value: Bool) {
        self.moduleDelegate?.didTextViewEditingStatusUpdate(with: value)
    }

    func didAttachmentsUpdate(_ update: AttachmentsUpdate, totalCount: Int) {
        self.moduleDelegate?.didAttachmentsUpdate(update, totalCount: totalCount)
    }

    func didVoiceMessageStatusUpdate(with status: VoiceMessageStatus) {
        self.moduleDelegate?.didVoiceMessageStatusUpdate(with: status)
    }

    func retrieveExistingDraft() -> MessageDraftProviding? {
        guard let draft = self.existingDraft else {
            return nil
        }

        return MessageDraftProvider(
            value: draft,
            dependencies: self.senderDependencies
        )
    }

    func removeExistingDraft() {
        guard let draft = self.existingDraft else {
            return
        }

        self.cacheService.delete(draft: draft)
        self.moduleDelegate?.didUpdateDraft(event: .empty(channelID: self.channelID))
    }

    func removeDraft(messageGUID: String) {
        guard let draft = self.draft(with: messageGUID) else {
            return
        }

        self.cacheService.delete(draft: draft)
    }

    func saveDraft(
        messageGUID: String,
        messageStatus: MessageStatus,
        text: String,
        attachments: [ContentSender]
    ) {
        let draftAttachments = attachments.compactMap { $0.makeDraftAttachment(with: self.senderDependencies) }
        let attachmentsInDraftContainer = DraftAttachmentsContainer(values: draftAttachments)

        let draft = MessageDraft(
            messageGUID: messageGUID,
            messageStatus: messageStatus,
            channelID: self.channelID,
            text: text,
            updatedAt: Date(),
            attachments: attachmentsInDraftContainer
        )

        self.cacheService.save(draft: draft)

        if draft.isEmpty {
            self.moduleDelegate?.didUpdateDraft(event: .empty(channelID: self.channelID))
            return
        }

        let preview = draft.makePreview(with: self.senderDependencies)
        self.moduleDelegate?.didUpdateDraft(event: .message(preview))
    }

    private func draft(with messageGUID: String) -> MessageDraft? {
        self.cacheService.retrieveDraft(channelID: self.channelID, messageGUID: messageGUID)
    }

    private func saveAsDraft(_ message: Message?, sender: ContentSender) {
        let text = sender.content?.rawContent ?? ""

        let guid = message?.guid ?? sender.messageGUID
        self.saveDraft(
            messageGUID: guid,
            messageStatus: message?.status ?? .draft,
            text: text,
            attachments: [sender]
        )
    }

    private var existingDraft: MessageDraft? {
        self.cacheService.retrieveDrafts( channelID: self.channelID ).first { $0.messageStatus == .draft }
    }

    private func makePreview(from message: Message) -> MessagePreview? {
        message.makePreview(
            clientID: self.clientID,
            channelID: self.clientID,
            cacheService: self.cacheService,
            senderDependencies: self.senderDependencies
        )
    }

    func willSendMessage(_ preview: MessagePreview?) {
        self.moduleDelegate?.willSendMessage(preview)
    }

    func decideIfMaySendMessage(_ message: MessagePreview, _ asyncDecisionBlock: @escaping (Bool) -> Void) {
        self.moduleDelegate?.decideIfMaySendMessage(message, asyncDecisionBlock)
    }

    func modifyTextBeforeSending(_ text: String) -> String {
        self.moduleDelegate?.modifyTextBeforeSending(text) ?? text
    }
}

extension ChatPresenter {
    // TODO @v.kiryukhin: move formatting-related code to separate factory
    private static let dateSeparatorFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.dateFormat = "dd MMMM"
        return formatter
    }()

    private static let dateSeparatorRelativeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    private static let messageTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

extension ChatPresenter {
    func persistSendStarted() {
        var channels = Self.channelsWithUnfinishedSends
        let count = channels[self.channelID] ?? 0
        channels[self.channelID] = count + 1
        Self.channelsWithUnfinishedSends = channels
    }

    func persistSendFinished() {
        var channels = Self.channelsWithUnfinishedSends
        guard let count = channels[self.channelID] else { return }
        channels[self.channelID] = count - 1

        if count <= 0 {
            channels[self.channelID] = nil
        }

        Self.channelsWithUnfinishedSends = channels
    }

    static var channelsWithUnfinishedSends: [String: Int] {
        get {
            (UserDefaults
                .standard
                .object(forKey: "ChatPresenterChannelsSendingMessages")
             as? [String: Int]) ?? [:]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ChatPresenterChannelsSendingMessages")
        }
    }
}
