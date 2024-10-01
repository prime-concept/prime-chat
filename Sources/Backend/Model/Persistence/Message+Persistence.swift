import Foundation
import GRDB

extension Message: CacheableModel {
    enum Columns {
        static let guid = Column(CodingKeys.guid)
        static let channelID = Column(CodingKeys.channelID)
        static let hostingChannelIDs = Column(CodingKeys.hostingChannelIDs)
        static let clientID = Column(CodingKeys.clientID)
        static let senderName = Column(CodingKeys.senderName)
        static let source = Column(CodingKeys.source)
        static let status = Column(CodingKeys.status)
        static let timestamp = Column(CodingKeys.timestamp)
        static let relativeOrder = Column(CodingKeys.relativeOrder)
        static let ttl = Column(CodingKeys.ttl)
        static let updatedAt = Column(CodingKeys.updatedAt)
        static let type = Column(CodingKeys.type)
        static let replyTo = Column(CodingKeys.replyTo)
        static let replyToID = Column(CodingKeys.replyToID)
        static let contentMeta = Column(CodingKeys.contentMeta)
        static let content = Column(CodingKeys.content)
    }

    static var databaseTableName: String { "messages" }

    init(row: Row) {
        let type: String = row[Columns.type.name] ?? "TEXT"
        let boxDecoder = row[Columns.content.name].flatMap { _DatabaseValueConvertibleBoxDecoder($0) }
        let content = boxDecoder.flatMap {
            Message.makeContentType(from: $0, type: MessageType(rawValue: type) ?? .text)
        }

        let contentMeta = ContentMeta.fromDatabaseValue(row[Columns.contentMeta.name])
        let replyTo = Message.fromDatabaseValue(row[Columns.replyTo.name])

        let hostingChannelIDsString: String = row[Columns.hostingChannelIDs.name] ?? ""
        let hostingChannelIDs = hostingChannelIDsString.components(separatedBy: ",")

        let order = row[Columns.relativeOrder.name] as? Int

        self.init(
            guid: row[Columns.guid.name],
            clientID: row[Columns.clientID.name],
            channelID: row[Columns.channelID.name],
            hostingChannelIDs: Set(hostingChannelIDs),
            timestamp: row[Columns.timestamp.name],
            relativeOrder: order ?? 0,
            source: row[Columns.source.name],
            senderName: row[Columns.senderName.name],
            status: row[Columns.status.name],
            ttl: row[Columns.ttl.name],
            updatedAt: row[Columns.updatedAt.name],
            content: content,
            contentMeta: contentMeta,
            replyToID: row[Columns.replyToID.name],
            replyTo: replyTo.flatMap { [$0] }
        )
    }

    func encode(to container: inout PersistenceContainer) {
        let hostingChannelIDsString = self.hostingChannelIDs.joined(separator: ",")

        container[Columns.guid.name] = self.guid
        container[Columns.channelID.name] = self.channelID
        container[Columns.clientID.name] = self.clientID
        container[Columns.hostingChannelIDs.name] = hostingChannelIDsString
        container[Columns.senderName.name] = self.senderName
        container[Columns.source.name] = self.source
        container[Columns.status.name] = self.status
        container[Columns.timestamp.name] = self.timestamp
        container[Columns.relativeOrder.name] = self.relativeOrder
        container[Columns.ttl.name] = self.ttl
        container[Columns.updatedAt.name] = self.updatedAt
        container[Columns.type.name] = self.content?.messageType.rawValue
        container[Columns.content.name] = self.content?.rawContent
        container[Columns.contentMeta.name] = self.contentMeta.databaseValue
        container[Columns.replyToID.name] = self.replyToID

        if let replyToMessage = self.replyTo?.first {
            container[Columns.replyTo.name] = replyToMessage.databaseValue
        }
    }

    static func createTable(in db: Database) throws {
        try db.create(
            table: Self.databaseTableName,
            body: { table in
                table.column(Columns.guid.name, .text)
                    .notNull()
                    .primaryKey(onConflict: .replace, autoincrement: false)

                table.column(Columns.hostingChannelIDs.name, .text).notNull().indexed()
                table.column(Columns.channelID.name, .text).notNull().indexed()
                table.column(Columns.clientID.name, .text).indexed()
                table.column(Columns.senderName.name, .text)
                table.column(Columns.source.name, .text).notNull()
                table.column(Columns.status.name, .text)
                table.column(Columns.timestamp.name, .integer).notNull()
                table.column(Columns.relativeOrder.name, .integer).notNull()
                table.column(Columns.ttl.name, .integer)
                table.column(Columns.updatedAt.name, .integer)
                table.column(Columns.type.name, .text).notNull()
                table.column(Columns.content.name, .text).notNull()
                table.column(Columns.contentMeta.name, .text).notNull()
                table.column(Columns.replyToID.name, .text)
                table.column(Columns.replyTo.name, .text)
            }
        )
    }

    static func deleteTable(in db: Database) throws {
        try db.create(
            table: Self.databaseTableName,
            body: { table in
                table.column(Columns.guid.name, .text)
                    .notNull()
                    .primaryKey(onConflict: .replace, autoincrement: false)

                table.column(Columns.hostingChannelIDs.name, .text).notNull().indexed()
                table.column(Columns.channelID.name, .text).notNull().indexed()
                table.column(Columns.clientID.name, .text).indexed()
                table.column(Columns.senderName.name, .text)
                table.column(Columns.source.name, .text).notNull()
                table.column(Columns.status.name, .text)
                table.column(Columns.timestamp.name, .integer).notNull()
                table.column(Columns.relativeOrder.name, .integer).notNull()
                table.column(Columns.ttl.name, .integer)
                table.column(Columns.updatedAt.name, .integer)
                table.column(Columns.type.name, .text).notNull()
                table.column(Columns.content.name, .text).notNull()
                table.column(Columns.contentMeta.name, .text).notNull()
                table.column(Columns.replyToID.name, .text)
                table.column(Columns.replyTo.name, .text)
            }
        )
    }
}

private final class _DatabaseValueConvertibleBoxDecoder: Decoder, SingleValueDecodingContainer {
    private let value: DatabaseValueConvertible

    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]

    init(_ value: DatabaseValueConvertible) {
        self.value = value
    }

    // swiftlint:disable unavailable_function
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        fatalError("Not implemented")
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError("Not implemented")
    }
    // swiftlint:enable unavailable_function

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        self
    }

    func decodeNil() -> Bool {
        return false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        if case .string(let value) = self.value.databaseValue.storage {
            return Bool(value) ?? false
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: String.Type) throws -> String {
        if case .string(let value) = self.value.databaseValue.storage {
            return value
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: Double.Type) throws -> Double {
        if case .double(let value) = self.value.databaseValue.storage {
            return value
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: Float.Type) throws -> Float {
        if case .double(let value) = self.value.databaseValue.storage {
            return Float(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: Int.Type) throws -> Int {
        if case .int64(let value) = self.value.databaseValue.storage {
            return Int(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        if case .int64(let value) = self.value.databaseValue.storage {
            return Int8(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        if case .int64(let value) = self.value.databaseValue.storage {
            return Int16(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        if case .int64(let value) = self.value.databaseValue.storage {
            return Int32(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        if case .int64(let value) = self.value.databaseValue.storage {
            return Int64(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        if case .int64(let value) = self.value.databaseValue.storage {
            return UInt(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        if case .int64(let value) = self.value.databaseValue.storage {
            return UInt8(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        if case .int64(let value) = self.value.databaseValue.storage {
            return UInt16(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        if case .int64(let value) = self.value.databaseValue.storage {
            return UInt32(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        if case .int64(let value) = self.value.databaseValue.storage {
            return UInt64(value)
        }

        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        throw DecodingError.dataCorruptedError(in: self, debugDescription: "")
    }
}

extension MessageSource: DatabaseValueConvertible { }
extension MessageStatus: DatabaseValueConvertible { }
extension ContentMeta: JSONDatabaseValueConvertible { }
extension Message: JSONDatabaseValueConvertible { }
