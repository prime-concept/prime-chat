import Foundation

public enum MessageSource: String, CaseIterable, Codable {
    case chat = "CHAT"
    case sms = "SMS"
    case email = "EMAIL"
    case whatsapp = "WHATSAPP"
    case telegram = "TELEGRAM"
    case unknown

    public init(from decoder: Decoder) throws {
        self = try Self(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

public enum MessageStatus: String, Codable, CaseIterable {
    public init!(_ rawValue: String) {
        if Self.allCases.contains(where: { $0.rawValue == rawValue }) {
            self.init(rawValue: rawValue)
        } else {
            self.init(rawValue: Self.unknown.rawValue)
        }
    }

    case draft = "DRAFT"
    case new = "NEW"
    case sent = "SENT"
    case sending = "SENDING"
    case reserved = "RESERVED"
    case seen = "SEEN"
    case deleted = "DELETED"
    case failed = "FAILED"
    case unknown = "UNKNOWN"

    public var isRemote: Bool {
        [.sent, .reserved, .seen, .deleted].contains(self)
    }

    public static let notSentStatuses: [Self] = [.draft, .new, .sending, .failed]

    public init(from decoder: Decoder) throws {
        self = try Self(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

struct Message: Codable, Equatable {
    private static var messageContentFactory: MessageContentFactory?

    var guid: String
    let clientID: String?

    let channelID: String
    var hostingChannelIDs: Set<String>

    var timestamp: Int
    
    // Вспомогательное значение для определения порядка сообщений
    // с одинаковым timestamp. Чем больше значение, тем "новее" сообщение.
    // Определяется порядком прихода с сервера, на абсолютное значение смотреть не стоит.
    var relativeOrder: Int = 0

    let source: MessageSource
    let senderName: String?
    var status: MessageStatus
    let ttl: Int?
    private(set) var updatedAt: Int?
    private(set) var content: MessageContent?
    var contentMeta: ContentMeta
    var replyToID: String?
    var replyTo: [Message]?

    var isUpdate: Bool {
        self.content == nil
    }

    var isMessage: Bool {
        !self.isUpdate
    }

    init(
        guid: String,
        clientID: String? = nil,
        channelID: String,
        hostingChannelIDs: Set<String>,
        timestamp: Int,
        relativeOrder: Int = 0,
        source: MessageSource = .chat,
        senderName: String? = nil,
        status: MessageStatus = .unknown,
        ttl: Int? = nil,
        updatedAt: Int? = nil,
        content: MessageContent? = nil,
        contentMeta: ContentMeta? = nil,
        replyToID: String? = nil,
        replyTo: [Message]? = nil
    ) {
        self.guid = guid
        self.clientID = clientID
        self.channelID = channelID
        self.hostingChannelIDs = hostingChannelIDs
        self.timestamp = timestamp
        self.relativeOrder = relativeOrder
        self.source = source
        self.senderName = senderName
        self.status = status
        self.ttl = ttl
        self.updatedAt = updatedAt
        self.content = content
        self.contentMeta = contentMeta ?? ContentMeta()
        self.replyToID = replyToID
        self.replyTo = replyTo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.guid = try container.decode(String.self, forKey: .guid)
        self.clientID = try container.decodeIfPresent(String.self, forKey: .clientID)
        self.channelID = try container.decode(String.self, forKey: .channelID)
        self.hostingChannelIDs = try container.decodeIfPresent(Set<String>.self, forKey: .hostingChannelIDs) ?? []
        self.timestamp = try container.decode(Int.self, forKey: .timestamp)
        self.source = try container.decode(MessageSource.self, forKey: .source)
        self.senderName = try container.decodeIfPresent(String.self, forKey: .senderName)
        self.status = (try? container.decodeIfPresent(MessageStatus.self, forKey: .status)) ?? .unknown
        self.ttl = try container.decodeIfPresent(Int.self, forKey: .ttl)
        self.updatedAt = try container.decodeIfPresent(Int.self, forKey: .updatedAt)
        self.contentMeta = (try? container.decode(ContentMeta.self, forKey: .contentMeta)) ?? ContentMeta()
        self.replyToID = try container.decodeIfPresent(String.self, forKey: .replyToID)
        self.replyTo = []
        if let replyToMessage = try? container.decodeIfPresent(Message.self, forKey: .replyTo) {
            self.replyTo?.append(replyToMessage)
        }

        let type = try? container.decodeIfPresent(MessageType.self, forKey: .type)
        if container.contains(.content) {
            guard let factory = Self.messageContentFactory else {
                fatalError("Inconsistent state: you must provide messageContentFactory before parsing content")
            }

            if
                let type = type,
                let content = try factory.make(
                    from: container.superDecoder(forKey: .content),
                    type: type),
                content.messageType == type
            {
                self.content = content
            } else {
                log(
                    sender: nil,
                    "Inconsistent state: there is no content types in factory for decoding: \(String(describing: type))"
                )
                self.content = nil
            }
        } else {
            self.content = nil
        }
    }

    enum CodingKeys: String, CodingKey {
        case guid
        case clientID = "clientId"
        case channelID = "channelId"
        case hostingChannelIDs
        case timestamp
        case relativeOrder
        case type
        case source
        case senderName
        case content
        case status
        case ttl
        case updatedAt
        case contentMeta = "meta"
        case replyToID = "replyToId"
        case replyTo
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.guid, forKey: .guid)
        try container.encodeIfPresent(self.clientID, forKey: .clientID)
        try container.encode(self.channelID, forKey: .channelID)
        try container.encode(self.timestamp, forKey: .timestamp)
        try container.encode(self.source, forKey: .source)
        try container.encodeIfPresent(self.senderName, forKey: .senderName)
        try container.encodeIfPresent(self.status, forKey: .status)
        try container.encodeIfPresent(self.ttl, forKey: .ttl)
        try container.encodeIfPresent(self.updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(self.contentMeta, forKey: .contentMeta)
        try container.encodeIfPresent(self.replyToID, forKey: .replyToID)
        try container.encodeIfPresent(self.hostingChannelIDs, forKey: .hostingChannelIDs)

        if let content = self.content {
            try container.encode(content.messageType, forKey: .type)
            try content.encode(to: container.superEncoder(forKey: .content))
        }
    }

    // MARK: - Public

    static func set(messageContentFactory: MessageContentFactory) {
        self.messageContentFactory = messageContentFactory
    }

    func copyUpdating(status: MessageStatus) -> Self {
        var newMessage = self
        newMessage.status = status
        return newMessage
    }

    func copyUpdating(updatedAt: Int?) -> Self {
        var newMessage = self
        newMessage.updatedAt = updatedAt
        return newMessage
    }

    func copyUpdating(timestamp: Int) -> Self {
        var newMessage = self
        newMessage.timestamp = timestamp
        return newMessage
    }

    func copyUpdating(content: MessageContent) -> Self {
        var newMessage = self
        newMessage.content = content
        return newMessage
    }

    func copyUpdating(guid: String) -> Self {
        var newMessage = self
        newMessage.guid = guid
        return newMessage
    }

    func copyUpdating(contentMeta: ContentMeta) -> Self {
        var newMessage = self
        newMessage.contentMeta = contentMeta
        return newMessage
    }

    static func makeContentType(from decoder: Decoder, type: MessageType) -> MessageContent? {
        return try? self.messageContentFactory?.make(from: decoder, type: type)
    }

    func isNewer(than message: Message) -> Bool {
        if self.timestamp == message.timestamp {
            if self.relativeOrder == message.relativeOrder {
                return self.guid > message.guid
            }
            return self.relativeOrder > message.relativeOrder
        }

        return self.timestamp > message.timestamp
    }
}

extension Message {
    func makePreview(
        clientID: String,
        channelID: String,
        contentRendererFactory: ChatDependencies.PresenterFactory = ChatDependencies.dummyPresenterFactory,
        cacheService: DraftsCacheServiceProtocol,
        senderDependencies: ContentSenderDependencies
    ) -> MessagePreview? {
        let existingDraft = cacheService
            .retrieveDrafts(channelID: channelID)
            .first { $0.messageGUID == self.guid && $0.messageStatus == .draft }

        if let existingDraft = existingDraft, !existingDraft.isEmpty {
            return existingDraft.makePreview(with: senderDependencies)
        }

        guard let content = self.content,
            let (rawContent, rawMeta) = self.makeRawContent() else {
            return nil
        }

        let previewContent: MessagePreview.Content = {
            let rawContent = MessagePreview.RawContent(
                type: content.messageType,
                content: rawContent,
                meta: rawMeta
            )

            let meta = self.contentMeta
            let processed = contentRendererFactory(content, meta).preview()

            return .init(
                processed: processed,
                raw: rawContent
            )
        }()

        return MessagePreview(
            guid: self.guid,
            channelID: self.channelID,
            clientID: self.clientID,
            source: self.source,
            status: self.status,
            ttl: self.ttl.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) },
            timestamp: Date(timeIntervalSince1970: TimeInterval(self.timestamp)),
            content: [previewContent],
            isIncome: self.clientID != clientID
        )
    }

    private func makeRawContent() -> (content: String, meta: [String: Any])? {
        guard let data = try? JSONEncoder().encode(self),
              let message = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
              let content = message["content"] as? String,
              let meta = message["meta"] as? [String: Any] else {
            return nil
        }
        return (content, meta)
    }

    var debugDescription: String {
        guard let content else {
            return "UPDATE FOR: " + guid + " " + self.channelID + " STATUS: " + self.status.rawValue
        }
        return "MESSAGE: "
        +  guid
        + " "
        + self.channelID
        + " \(updatedAt ?? 0)"
        + " "
        + self.status.rawValue
        + " "
        + content.rawContent
    }
}

extension Message {
    var description: String {
        let type = self.content?.messageType.rawValue ?? "NULL"
        let description = "\(status) \(guid) \(timestamp) (\(Date(timeIntervalSince1970: Double(timestamp)))): \(type)"
        return description
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.guid == rhs.guid &&
        lhs.status == rhs.status &&
        lhs.updatedAt == lhs.updatedAt
    }
}
