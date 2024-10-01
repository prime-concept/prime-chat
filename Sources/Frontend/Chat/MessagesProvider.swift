import Foundation

// MARK: - MessagesProviderProtocol

extension Notification.Name {
    static let messagesProviderDisplayableMessagesChanged = Self.init(
        rawValue: "messagesProviderDisplayableMessagesChanged"
    )
}

protocol MessagesProviderProtocol: AnyObject, AutoMockable {
    var displayableMessages: [Message] { get }

    /*
     Именно к этим load-методам идет паломничество вызовов по всему чату.
     У методов сработает колбэк и цепочка начнет раскручиваться в обратном порядке:

     В комплишене будет лежать ChatPresenter, общий знаменатель между контроллером
     ленты и контроллером поля ввода текста.
     ChatPresenter дернет метод update... у MessagesListController-a
     Контроллер - update... у MessageListPresenter-а
     Презентер - update... у контроллера MessagesListViewController
     Контроллер - update... у датасурса MessagesListDataSource,
     где уже отрелоудится collectionView.
     */
    func loadInitialMessages(completion: MessagesProviderCallback?)
    func loadOlderMessages(completion: MessagesProviderCallback?)
    func loadNewerMessages(completion: MessagesProviderCallback?)

    @discardableResult
    func saveMessage(_ message: Message) -> MessagesProviderCallbackData

    @discardableResult
    func deleteMessage(_ message: Message) -> MessagesProviderCallbackData
}

// MARK: - MessagesProvider

private let messagesProviderBatchSize = 20

// swiftlint:disable:next type_body_length
final class MessagesProvider: MessagesProviderProtocol {

    let channelID: String

    @ThreadSafe
    private static var messagesLoadQueues = [String: DispatchQueue]()

    private static let queueAccessLock = NSRecursiveLock()

    private lazy var queueLabel = "ChatSDK.MessagesProvider.MessagesLoadQueue-\(self.channelID)"
    private var messagesLoadQueue: DispatchQueue {
        Self.queueAccessLock.locked {
            if let queue = Self.messagesLoadQueues[self.queueLabel] {
                return queue
            }

            let queue = DispatchQueue(label: self.queueLabel, qos: .userInitiated)
            Self.messagesLoadQueues[self.queueLabel] = queue
            return queue
        }
    }

    private let messagesClient: MessagesClientProtocol
    private let messagesCacheService: MessagesCacheServiceProtocol

    private let messageTypesToIgnore: [MessageType]

    private(set) var cacheMayHaveOlderMessages = true
    private(set) var remoteMayHaveOlderMessages = true {
        didSet {
            if !self.remoteMayHaveOlderMessages {
                log(sender: self, "\(self.channelID) remoteMayHaveOlderMessages == FALSE !!!")
            }
        }
    }

    private lazy var oldestGUIDKey = "chat-\(self.channelID)-oldestMessageGUID"
    private lazy var newestGUIDKey = "chat-\(self.channelID)-newestMessageGUID"

    private var oldestMessageGUID: TimedGUID? {
        get {
            let value = TimedGUID.read(from: self.oldestGUIDKey)
            return value
        }
        set {
            newValue.write(to: self.oldestGUIDKey)
        }
    }

    private var newestMessageGUID: TimedGUID? {
        get {
            let value = TimedGUID.read(from: self.newestGUIDKey)
            return value
        }
        set {
            newValue.write(to: self.newestGUIDKey)
        }
    }

    private var orderCounter = 0

    var displayableMessages: [Message] {
        didSet {
            self.displayableMessages = displayableMessages.sorted {
                $0.isNewer(than: $1)
            }
        }
    }

    private var currentTime: Int {
        return Int(Date().timeIntervalSince1970)
    }

    init(
        channelID: String,
        messagesClient: MessagesClientProtocol,
        messagesCacheService: MessagesCacheServiceProtocol,
        messageTypesToIgnore: [MessageType] = []
    ) {
        self.messagesClient = messagesClient
        self.messagesCacheService = messagesCacheService
        self.messageTypesToIgnore = messageTypesToIgnore
        
        self.channelID = channelID

        self.displayableMessages = []

        Notification.onReceive(.messagesProviderDisplayableMessagesChanged) { [weak self] notification in
            self?.displayableMessagesChanged(notification)
        }
    }

    deinit {
        self.clearOnDeinit()
    }

    func loadInitialMessages(completion: MessagesProviderCallback?) {
        log(sender: self, "\(self.channelID) WILL LOAD INITIAL MESSAGES")

        let limit = 2 * messagesProviderBatchSize
        let cached = self.loadCachedMessages(from: nil, limit: limit)
        var data = cached.data
        data.isLoading = !cached.isEnough

        log(sender: self, "1. loadInitialMessages - loader - start")
        completion?(data)

        self.loadNewerMessages { [weak self] data in
            completion?(data)

            // Remote messages not loaded. 
            // We just indicated that loading started.
            if data.isLoading { return }

            guard let self else { return }

            if cached.isEnough {
                log(sender: self, "\(self.channelID) \(#function) WILL SKIP LOADING OLDER, CACHED ARE ENOUGH")
                return
            }

            self.loadOlderMessages(
                startingFrom: self.oldestMessageGUID?.guid,
                limit: limit,
                completion: completion
            )
        }
    }

    func loadOlderMessages(completion: MessagesProviderCallback?) {
        let guid = self.oldestMessageGUID?.guid

        self.loadOlderMessages(
            startingFrom: guid,
            completion: completion
        )
    }

    func loadNewerMessages(completion: MessagesProviderCallback?) {
        self.messagesLoadQueue.async { [weak self] in
            guard let self = self else { return }

            log(sender: self, "\(self.channelID) WILL LOAD NEWER MESSAGES")

            let guid = self.newestMessageGUID?.guid
            let limit = guid == nil ? 2 * messagesProviderBatchSize : nil

            self.loadRemoteMessages(
                startingFrom: guid,
                channelID: self.channelID,
                limit: limit,
                direction: .newer
            ) { data in
                log(sender: self, "8. loadNewerMessages - loadRemoteMessages - still load? \(data.isLoading)")
                completion?(data)
            }
        }
    }

    @discardableResult
    func deleteMessage(_ message: Message) -> MessagesProviderCallbackData {
        let message = message.copyUpdating(status: .deleted)
        displayableMessages = displayableMessages.filter { $0.guid != message.guid }
        self.messagesCacheService.delete(messages: [message])

        return MessagesProviderCallbackData(
            messages: self.displayableMessages,
            hasOlderMessages: self.remoteMayHaveOlderMessages
        )
    }

    @discardableResult
    func saveMessage(_ message: Message) -> MessagesProviderCallbackData {
        let oldMessageExists = self.displayableMessages.contains { $0.guid == message.guid }

        if oldMessageExists {
            self.displayableMessages = self.displayableMessages.map {
                $0.guid == message.guid ? message : $0
            }
        } else {
            self.displayableMessages.insert(message, at: 0)
        }

        self.save(messages: [message])

        return MessagesProviderCallbackData(
            messages: self.displayableMessages,
            hasOlderMessages: self.remoteMayHaveOlderMessages
        )
    }

    // MARK: - Private
    private func displayableMessagesChanged(_ notification: Notification) {
        guard let messages = notification.userInfo?["messages"] as? [Message] else {
            return
        }

        self.displayableMessages = self.displayableMessages.map { oldMessage in
            let newMessage = messages.first { $0.guid == oldMessage.guid }
            return newMessage ?? oldMessage
        }
    }

    // Это метод по загрузке сообщений вверх по истории, к самому старому.
    // Сперва смотрим, может у нас в кэше есть нужный интервал сообщений.
    // Если есть, берем его и выходим, вызвав все комплишены.
    // Если нет, смотрим, а есть ли более старые сообщения на бэке.
    // Если НЕТ, то выходим, вызвав все комплишены.
    // Если есть, то качаем их с бэка и вызываем комплишены после ответа бэка.
    private func loadOlderMessages(
        startingFrom guid: String?,
        limit: Int = messagesProviderBatchSize,
        completion: MessagesProviderCallback? = nil
    ) {
        log(sender: self, "WILL LOAD OLDER")

        self.messagesLoadQueue.async { [weak self] in
            guard let self = self else { return }

            let cache = self.loadCachedMessages(from: guid, limit: limit)

            let mayLoadOlder = self.cacheMayHaveOlderMessages || self.remoteMayHaveOlderMessages

            var data = cache.data
            data.hasOlderMessages = mayLoadOlder
            data.isLoading = mayLoadOlder && !cache.isEnough

            completion?(data)

            if cache.isEnough {
                return
            }

            guard mayLoadOlder else {
                log(
                    sender: self,
                    """
                    \(channelID) \
                    LOAD OLDER, REMOTE IS EXHAUSTED, WILL CALL onLoad WITH \
                    \(displayableMessages.count) DISPLAYABLE MESSAGES AND STOP
                    """
                )
                return
            }

            let oldestGuid = self.oldestMessageGUID?.guid
            log(sender: self, "\(self.channelID) WILL LOAD OLDER MESSAGES from \(oldestGuid ?? "NULL")")
            
            self.loadRemoteMessages(
                startingFrom: oldestGuid,
                channelID: self.channelID,
                limit: limit,
                direction: .older,
                completion: { data in
                    log(
                        sender: self,
                        "9. loadOlderMessages - loadRemoteMessages - stop - still load? \(data.isLoading)"
                    )
                    completion?(data)
                }
            )
        }
    }

    // TODO попросить Юру допилить Чат. Потому что запрос Newer при передаче самого последнего guid
    // не останавливается и раз за разом вертает одну и ту же пачку сообщений.
    private var lastBatchOfMessages = [MessagesLoadDirection: [Message]]()

    // swiftlint:disable:next function_body_length
    private func loadRemoteMessages(
        startingFrom guid: String?,
        channelID: String?,
        limit: Int?,
        direction: MessagesLoadDirection,
        completion: MessagesProviderCallback?
    ) {
        log(sender: self, "2. loadRemoteMessages - start, loader")
        completion?(MessagesProviderCallbackData(
            messages: self.displayableMessages,
            direction: direction,
            isLoading: true
        ))

        do {
            _ = try self.messagesClient.retrieve(
                channelID: channelID,
                guid: guid,
                limit: limit,
                time: self.currentTime,
                fromTime: nil,
                toTime: nil,
                direction: direction
            ) { [weak self] response in
                
                guard let self else {
                    log(sender: self, "3. loadRemoteMessages - client - self nil")
                    completion?(MessagesProviderCallbackData(
                        messages: [],
                        direction: direction,
                        isLoading: false
                    ))
                    return
                }

                switch response {
                case .success(let result):
                    guard 200...299 ~= result.httpStatusCode else {
                        let error = NSError(domain: "Chat", code: result.httpStatusCode)
                        log(sender: self, "4. loadRemoteMessages - client - BAD STATUS")
                        completion?(MessagesProviderCallbackData(
                            messages: self.displayableMessages,
                            direction: direction,
                            isLoading: false,
                            error: error))
                        return
                    }

                    let messages = result.data?.items ?? []

                    log(
                        sender: self,
                        "\(self.channelID) MES_STATS: DID LOAD \(direction == .newer ? "NEWER" : "OLDER") MESSAGES:"
                    )
                    log(sender: self, "WERE: \(self.displayableMessages.count), LOADED: \(messages.count)")

                    self.printMessagesStats(self.displayableMessages)

                    log(
                        sender: self,
                        "\(channelID) MES_STATS: \(self.channelID) MES_STATS: FROM BACKEND \(messages.count)"
                    )
                    self.printMessagesStats(messages)

                    self.updateOldestNewestGUIDs(with: messages)

                    let (appendedCount, updatedCount) = self.mergeDisplayableMessages(with: messages)
                    self.save(messages: self.displayableMessages)
                    self.logMerged(appendedCount, updatedCount)

                    if direction == .older {
                        self.remoteMayHaveOlderMessages = messages.count > 0
                    }

                    let previousMessages = self.lastBatchOfMessages[direction]
                    self.lastBatchOfMessages[direction] = messages

                    let directionString = (direction == .newer) ? "NEW" : "OLD"

                    // Значит мы загрузили пачку каких-то апдейтов,
                    // неотображаемых типов сообщений итп,
                    // а показать нам и нечего. Качаем дальше!
                    if messages.count > 0, appendedCount == 0, messages != previousMessages {
                        let guid = (direction == .newer) ? self.newestMessageGUID?.guid : self.oldestMessageGUID?.guid

                        log(
                            sender: self,
                            """
                            \(channelID) \
                            MES_STATS: \(directionString) \
                            НИЧЕГО НЕ ЗАКАЧАЛИ, ПРОБУЕМ ЕЩЕ РАЗ, С \(guid ?? "NULL")
                            """
                        )

                        self.loadRemoteMessages(
                            startingFrom: guid,
                            channelID: channelID,
                            limit: limit,
                            direction: direction,
                            completion: completion
                        )
                        return
                    }

                    log(
                        sender: self,
                        """
                        \(channelID) LOAD REMOTE \(directionString), \
                        WILL CALL onLoad WITH \(displayableMessages.count) DISPLAYABLE MESSAGES
                        """
                    )

                    log(sender: self, "5. loadRemoteMessages - client - OK")
                    completion?(MessagesProviderCallbackData(
                        messages: self.displayableMessages,
                        direction: direction,
                        hasOlderMessages: self.remoteMayHaveOlderMessages,
                        isLoading: false
                    ))
                case .failure:
                    log(sender: self, "6. loadRemoteMessages - client - RESP FAILED")
                    let error = NSError(domain: "Chat", code: -1)
                    completion?(MessagesProviderCallbackData(
                        messages: self.displayableMessages,
                        direction: direction,
                        isLoading: false,
                        error: error
                    ))
                }
            }
        } catch {
            log(sender: self, "7. loadRemoteMessages - client - CLIENT FAILED")
            completion?(MessagesProviderCallbackData(
                messages: self.displayableMessages,
                direction: direction,
                isLoading: false,
                error: error
            ))
        }
    }

    func printMessagesStats(_ messages: [Message]) {
        if messages.isEmpty {
            log(sender: self, "\(self.channelID) MES_STATS: EMPTY")
            return
        }

        let sorted = messages.sorted { $0.isNewer(than: $1) }
        let newest = sorted.first!
        let oldest = sorted.last!

        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY/MM/dd hh:mm:ss"
        let date1 = formatter.string(from: Date(timeIntervalSince1970: Double(oldest.timestamp)))
        let date2 = formatter.string(from: Date(timeIntervalSince1970: Double(newest.timestamp)))

        log(
            sender: self,
            "\(channelID) MES_STATS: OLDEST \(oldest.guid), \((oldest.content?.rawContent ?? "").prefix(10)) @ \(date1)"
        )
        log(
            sender: self,
            "\(channelID) MES_STATS: NEWEST \(newest.guid), \((newest.content?.rawContent ?? "").prefix(10)) @ \(date2)"
        )
    }

    private func viableMessages(from remoteEntries: [Message]) -> [Message] {
        remoteEntries.filter { message in
            guard message.isMessage, message.status != .deleted else { return false }
            
            // FIXME: As long as `messageTypesToIgnore` is an array, this code has quadratic complexity
            if let messageType = message.content?.messageType, messageTypesToIgnore.contains(messageType) {
                return false
            } else {
                return true
            }
        }
    }

    // The reason I don't call array [Message] messages
    // is that a Message can either be a full-fledged message,
    // or merely an update of a local message, with a changed status and no text.
    @discardableResult
    private func mergeDisplayableMessages(
        with remoteEntries: [Message]
    ) -> (newCount: Int, updatedCount: Int) {
        if remoteEntries.isEmpty {
            return (0, 0)
        }

        let remoteEntries = remoteEntries.sorted { $0.isNewer(than: $1) }
        let remoteMessages = self.viableMessages(from: remoteEntries)

        if self.displayableMessages.isEmpty {
            self.displayableMessages = remoteMessages
        }

        var updatedMessagesGuids = Set<String>()

        var localMessagesMap = self.displayableMessages.reduce(into: [:]) { map, message in
            map[message.guid] = message
        }

        let deletedMessages = remoteEntries.filter { $0.status == .deleted }
        for message in deletedMessages {
            localMessagesMap.removeValue(forKey: message.guid)
            updatedMessagesGuids.insert(message.guid)
        }

        let updates = Array(remoteEntries.filter(\.isUpdate).reversed())
        for update in updates {
            guard let localMessage = localMessagesMap[update.guid] else {
                continue
            }

            localMessagesMap[update.guid] = localMessage
                .copyUpdating(status: update.status)
                .copyUpdating(updatedAt: update.updatedAt)

            updatedMessagesGuids.insert(localMessage.guid)
        }

        let newMessages = remoteMessages.filter { localMessagesMap[$0.guid] == nil }
        let rewrittenMessages = remoteMessages.filter { localMessagesMap[$0.guid] != nil }

        rewrittenMessages.forEach { remoteMessage in
            guard let localMessage = localMessagesMap[remoteMessage.guid] else {
                return
            }

            if remoteMessage.isNewer(than: localMessage) {
                localMessagesMap[localMessage.guid] = remoteMessage
                updatedMessagesGuids.insert(localMessage.guid)
            }
        }

        let mergedMessages = (localMessagesMap.values + newMessages).sorted { $0.isNewer(than: $1) }
        self.displayableMessages = mergedMessages

        return (newMessages.count, updatedMessagesGuids.count)
    }

    private func logMerged(_ appendedCount: Int, _ updatedCount: Int) {
        log(sender: self,
            "\(self.channelID) batch merged\n"
            + "\tnew = \(appendedCount)\n"
            + "\tupdated = \(updatedCount)\n"
            + "\ttotal = \(self.displayableMessages.count)"
        )
    }

    private func save(messages: [Message]) {
        let existingGuids = messages.map(\.guid)
        let existingMessages = self.messagesCacheService.retrieveMessages(guids: existingGuids)

        let messages = messages.map {
            var message = $0
            message.hostingChannelIDs.insert(self.channelID)

            let existingMessage = existingMessages.first { $0.guid == message.guid }
            let existingMessageGuids = existingMessage?.hostingChannelIDs ?? []

            message.hostingChannelIDs = message.hostingChannelIDs.union(existingMessageGuids)

            if message.relativeOrder == 0 {
                message.relativeOrder = existingMessage?.relativeOrder ?? {
                    self.orderCounter += 1
                    return self.orderCounter
                }()
            }

            return message
        }

        self.messagesCacheService.save(messages: messages)
    }

    private func updateOldestNewestGUIDs(with messages: [Message]) {
        if messages.isEmpty {
            return
        }
        
        let sortedMessages = messages.sorted { $0.isNewer(than: $1) }

        let newestMessage = sortedMessages.first!
        let oldestMessage = sortedMessages.last!

        if self.newestMessageGUID == nil || newestMessage.timestamp > self.newestMessageGUID!.timestamp {
            self.newestMessageGUID = TimedGUID(timestamp: newestMessage.timestamp, guid: newestMessage.guid)
        }

        if self.oldestMessageGUID == nil || oldestMessage.timestamp < self.oldestMessageGUID!.timestamp {
            self.oldestMessageGUID = TimedGUID(timestamp: oldestMessage.timestamp, guid: oldestMessage.guid)
        }
    }

    private func clearOnDeinit() {
        self.displayableMessages.forEach { message in
            ContentRendererCache.shared.values.removeValue(forKey: message.guid)
        }
    }
}

fileprivate extension MessagesProvider {
    private func loadCachedMessages(from guid: String?, limit: Int) -> (
        data: MessagesProviderCallbackData, isEnough: Bool
    ) {
        let initialMessagesCount = self.displayableMessages.count
        
        var offset: Int! = self.displayableMessages.firstIndex { $0.guid == guid }
        offset = offset ?? self.displayableMessages.count

        var messagesLoaded = 0

        while self.cacheMayHaveOlderMessages, messagesLoaded < limit {
            let cachedBatch = self.messagesCacheService.retrieve(
                channelID: self.channelID,
                limit: limit,
                from: offset
            )

            offset += cachedBatch.count
            self.mergeDisplayableMessages(with: cachedBatch)
            self.cacheMayHaveOlderMessages = cachedBatch.count > 0

            messagesLoaded = self.displayableMessages.count - initialMessagesCount
        }

        if messagesLoaded >= limit {
            log(sender: self, "\(self.channelID) loadCachedMessages, loaded \(messagesLoaded) of \(limit)")
        }

        let isEnough = messagesLoaded >= limit

        let data = MessagesProviderCallbackData(
            messages: self.displayableMessages,
            direction: .older,
            hasOlderMessages: self.cacheMayHaveOlderMessages
        )

        return (data, isEnough)
    }
}
