import Foundation
import GRDB

public struct DraftAttachment: Equatable, JSONDatabaseValueConvertible {
    typealias JSON = String

    let type: String
    let properties: JSON
}

struct DraftAttachmentsContainer: Equatable, JSONDatabaseValueConvertible {
    let values: [DraftAttachment]
}

struct MessageDraft: CacheableModel, Equatable {
    enum Columns {
        static let messageGUID = Column("messageGUID")
        static let channelID = Column("channelID")
        static let text = Column("text")
        static let attachments = Column("attachments")
        static let updatedAt = Column("updatedAt")
        static let messageStatus = Column("messageStatus")
    }

    private static var contentSenders: [ContentSender.Type] = []

    static var databaseTableName: String { "drafts" }

    let messageGUID: String
    let channelID: String
    var text: String
    var updatedAt: Int
    let attachments: DraftAttachmentsContainer
    var messageStatus: MessageStatus

    var isEmpty: Bool {
        self.text.isEmpty && self.attachments.values.isEmpty
    }

    init(
        messageGUID: String,
        messageStatus: MessageStatus = .draft,
        channelID: String,
        text: String,
        updatedAt: Date,
        attachments: DraftAttachmentsContainer
    ) {
        self.messageGUID = messageGUID
        self.messageStatus = messageStatus
        self.channelID = channelID
        self.text = text
        self.updatedAt = Int(updatedAt.timeIntervalSince1970)
        self.attachments = attachments
    }

    init(row: Row) {
        self.messageGUID = row[Columns.messageGUID.name]
        self.channelID = row[Columns.channelID.name]
        self.text = row[Columns.text.name]
        self.updatedAt = row[Columns.updatedAt.name]
        self.attachments = DraftAttachmentsContainer.fromDatabaseValue(row[Columns.attachments.name])
        ?? DraftAttachmentsContainer(values: [])
        self.messageStatus = row[Columns.messageStatus.name]
    }

    func encode(to container: inout PersistenceContainer) {
        container[Columns.messageGUID.name] = self.messageGUID
        container[Columns.text.name] = self.text
        container[Columns.channelID.name] = self.channelID
        container[Columns.updatedAt.name] = self.updatedAt
        container[Columns.attachments.name] = self.attachments.databaseValue
        container[Columns.messageStatus.name] = self.messageStatus
    }

    func getSendersForAttachments(with dependencies: ContentSenderDependencies) -> [ContentSender] {
        var senders: [ContentSender] = []

        for item in self.attachments.values {
            let sender = MessageDraft.contentSenders
                .compactMap { type in
                    type.from(draftAttachment: item, dependencies: dependencies)
                }
                .first

            sender.flatMap { senders.append($0) }
        }

        return senders
    }

    static func set(contentSenders: [ContentSender.Type]) {
        self.contentSenders = contentSenders
    }

    static func createTable(in db: Database) throws {
        try db.create(
            table: Self.databaseTableName,
            body: { table in
                table.column(Columns.messageGUID.name, .text)
                    .notNull()
                    .primaryKey(onConflict: .replace, autoincrement: false)
                table.column(Columns.channelID.name, .text)
                table.column(Columns.text.name, .text).notNull().indexed()
                table.column(Columns.updatedAt.name, .numeric).notNull()
                table.column(Columns.attachments.name, .text).notNull()
                table.column(Columns.messageStatus.name, .text)
            }
        )
    }

    static func emptyDraft(channelID: String) -> Self {
        MessageDraft(
            messageGUID: "",
            messageStatus: .draft,
            channelID: channelID,
            text: "",
            updatedAt: Date(),
            attachments: .init(values: [])
        )
    }
}

struct MessageDraftProvider: MessageDraftProviding {
    let value: MessageDraft
    let dependencies: ContentSenderDependencies

    var guid: String { value.messageGUID }
    var text: String { value.text }

    var attachments: [ContentSender] {
        return self.value.getSendersForAttachments(with: self.dependencies)
    }
}

extension MessageDraft {
    func makePreview(with dependencies: ContentSenderDependencies) -> MessagePreview {
        // One or many previews e.g text + two photo attachments
        var contents: [MessagePreview.Content] = []

        if !self.text.isEmpty {
            contents.append(
                .init(
                    processed: .text(self.text),
                    raw: .init(type: TextContent.messageType, content: self.text, meta: [:])
                )
            )
        }

        let senders = self.getSendersForAttachments(with: dependencies)

        if !senders.isEmpty {
            for sender in senders {
                contents.append(sender.contentPreview)
            }
        }

        var status = self.messageStatus
        status = status == .unknown ? .draft : status

        return MessagePreview(
            guid: "draft_\(self.channelID)_\(self.messageGUID)",
            channelID: self.channelID,
            clientID: nil,
            source: .chat,
            status: status,
            ttl: nil,
            timestamp: Date(timeIntervalSince1970: Double(self.updatedAt)),
            content: contents,
            isIncome: false
        )
    }
}
