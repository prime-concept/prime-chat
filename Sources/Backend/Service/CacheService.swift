import Foundation
import GRDB

protocol MessagesCacheServiceProtocol: AnyObject {
    func retrieveLastMessages() -> [Message]
    func retrieveMessages(guids: [String]) -> [Message]
    func retrieve(channelID: String, limit: Int, from: Int) -> [Message]
    func retrieve(channelID: String, limit: Int, offsetGUID: String?, requestOlderMessages: Bool) -> [Message]
    
    func save(messages: [Message])
    func delete(messages: [Message])
}

protocol DraftsCacheServiceProtocol: FilesCacheServiceProtocol {
    func retrieveDrafts(channelID: String) -> [MessageDraft]
    func retrieveDraft(channelID: String, messageGUID: String) -> MessageDraft?
    func save(draft: MessageDraft)
    func delete(draft: MessageDraft)
}

protocol FilesCacheServiceProtocol {
    func exists(file: FileInfo) -> URL?
    func exists(cacheKey: String) -> URL?

    func retrieve(file: FileInfo) -> Data?
    func retrieve(cacheKey: String) -> Data?

    @discardableResult
    func save(cacheKey: String, data: Data) -> URL?
    @discardableResult
    func save(file: FileInfo, data: Data) -> URL?
    func erase()
}

protocol CacheServiceProtocol: MessagesCacheServiceProtocol, DraftsCacheServiceProtocol, AutoMockable { }

protocol CacheableModel: FetchableRecord, PersistableRecord {
    static func createTable(in db: Database) throws
}

final class CacheService: CacheServiceProtocol {
    private let dbPool: DatabaseWriter?
    private var activeDraftTrackingCancellable: DatabaseCancellable?
    private let filesCacheService: FilesCacheServiceProtocol

    static var cacheDirectory: URL? {
        try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    init(
        filesCacheService: FilesCacheServiceProtocol = FilesCacheService(cacheDirectory: CacheService.cacheDirectory),
        pool: DatabaseWriter?
    ) {
        log(sender: nil, "\(CacheService.self) initializing cache...")
        self.filesCacheService = filesCacheService
        self.dbPool = pool

        guard let pool else {
            assertionFailure("Database pool didn't initialize")
            return
        }

        migrateIfNeeded(pool: pool)
        Notification.onReceive(.shouldClearCache, .loggedOut) { [weak self] _ in
            self?.clearCache()
        }
    }


    private let eraseLock = NSLock()

    @objc
    private func clearCache() {
        self.eraseLock.locked {
            try? self.dbPool?.erase()
            try? self.dbPool?.write { db in
                try? Message.createTable(in: db)
                try? MessageDraft.createTable(in: db)
            }
            self.filesCacheService.erase()
        }
    }

    func retrieve(channelID: String, limit: Int, from: Int) -> [Message] {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return []
        }

        do {
            return try pool.read { db -> [Message] in
                let messages = try Message
                    .filter(Message.Columns.hostingChannelIDs.like("%\(channelID)%"))
                    .order(Message.Columns.timestamp.desc)
                    .limit(limit, offset: from)
                    .fetchAll(db)

                return messages
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "cache db fetch error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func retrieveMessages(guids: [String]) -> [Message] {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return []
        }

        // Оставляем только безопасные гуиды, в которых нет символов,
        // запрещенных в гуид-строке.
        // 123-abc-45 -- ОК
        // 123-abc-45';DROP TABLE MESSAGES; -- нет
        let sanitizedGuids = guids.filter { guid in
            !guid.contains(regex: "[^a-zA-Z0-9\\-]")
        }

        do {
            return try pool.read { db -> [Message] in
                let guidsArray = "('\(sanitizedGuids.joined(separator: "', '"))')"
                let tableName = Message.databaseTableName
                let columnName = Message.Columns.guid.name
                let query = "SELECT * FROM \(tableName) WHERE \(columnName) IN \(guidsArray)"

                return try Message.fetchAll(db, sql: query)
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) retrieve Messages",
                "details": "\(#function) cache db fetch error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func retrieve(
        channelID: String,
        limit: Int,
        offsetGUID: String?,
        requestOlderMessages: Bool = true
    ) -> [Message] {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return []
        }

        do {
            return try pool.read { db -> [Message] in
                if let offset = offsetGUID,
                   let guidRow = try? Message
                    .filter(Message.Columns.hostingChannelIDs.like("%\(channelID)%"))
                    .filter(Message.Columns.guid == offset)
                    .fetchOne(db) {
                    let messages = try Message
                        .filter(Message.Columns.hostingChannelIDs.like("%\(channelID)%"))
                        .order(Message.Columns.timestamp.desc)
                        .filter(
                            requestOlderMessages
                            ? Message.Columns.timestamp <= guidRow.timestamp
                            : Message.Columns.timestamp >= guidRow.timestamp
                        )
                        .filter(Message.Columns.guid != guidRow.guid)
                        .limit(limit)
                        .fetchAll(db)

                    return messages
                }

                return try Message
                    .filter(Message.Columns.hostingChannelIDs.like("%\(channelID)%"))
                    .order(Message.Columns.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) retrieve Messages",
                "details": "\(#function) cache db fetch error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db fetch error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Private

    private static func dbPath(for clientID: String) -> String? {
        Self.cacheDirectory?
            .appendingPathComponent("chat_cache_\(clientID).sqlite", isDirectory: false)
            .absoluteString
    }

    private func migrateIfNeeded(pool: DatabaseWriter) {
        var migrator = DatabaseMigrator()

#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif

        defer {
            try? migrator.migrate(pool)
        }

        migrator.registerMigration("initial_setup") { db in
            do {
                try Message.createTable(in: db)
            } catch {
                print("initial_setup failed with \(error)")
            }
        }

        migrator.registerMigration("drafts_setup") { db in
            do {
                try MessageDraft.createTable(in: db)
            } catch {
                print("drafts_setup failed with \(error)")
            }
        }

        migrator.registerMigration("messages_hostingChannelIDs") { db in
            try db.alter(table: Message.databaseTableName) { t in
                let columns = (try? db.columns(in: "messages")) ?? []

                if columns.contains(where: { $0.name == "hostingChannelIDs" }) {
                    return
                }

                if columns.contains(where: { $0.name == "owningChannelID" }) {
                    t.rename(column: "owningChannelID", to: "hostingChannelIDs")
                    return
                }

                t.add(column: "hostingChannelIDs", .text)
            }
        }

        migrator.registerMigration("messages_relativeOrder6") { db in
            try db.alter(table: Message.databaseTableName) { t in
                let columns = (try? db.columns(in: "messages")) ?? []

                if columns.contains(where: { $0.name == "relativeOrder" }) {
                    return
                }

                t.add(column: "relativeOrder", .integer)
            }
        }

        // Place new migrations if needed below
    }
}

// MARK: - MessagesCacheServiceProtocol

extension CacheService {
    func retrieveDrafts(
        channelID: String,
        limit: Int,
        offsetGUID: String?,
        requestOlderMessages: Bool = true
    ) -> [Message] {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return []
        }

        do {
            return try pool.read { db -> [Message] in
                if let offset = offsetGUID,
                   let guidRow = try? Message
                    .filter(Message.Columns.channelID == channelID)
                    .filter(Message.Columns.guid == offset)
                    .fetchOne(db) {
                    return try Message
                        .filter(Message.Columns.channelID == channelID)
                        .order(Message.Columns.timestamp.desc)
                        .filter(
                            requestOlderMessages
                            ? Message.Columns.timestamp <= guidRow.timestamp
                            : Message.Columns.timestamp >= guidRow.timestamp
                        )
                        .filter(Message.Columns.guid != guidRow.guid)
                        .limit(limit)
                        .fetchAll(db)
                }

                return try Message
                    .filter(Message.Columns.channelID == channelID)
                    .order(Message.Columns.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) retrieveDrafts",
                "details": "\(#function) cache db fetch error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func retrieveLastMessages() -> [Message] {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return []
        }

        do {
            return try pool.read { db -> [Message] in
                let knownChannels = try Message
                    .select(Message.Columns.channelID, as: String.self)
                    .distinct()
                    .fetchAll(db)

                return try knownChannels.compactMap { channelID in
                    try Message
                        .order(Message.Columns.timestamp.desc)
                        .filter(Message.Columns.channelID == channelID)
                        .limit(1)
                        .fetchOne(db)
                }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "cache db fetch error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func save(messages: [Message]) {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return
        }

        do {
            try pool.write { db in
                try messages.forEach { try $0.save(db) }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "cache db fetch error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db write error: \(error.localizedDescription)")
        }
    }

    func delete(messages: [Message]) {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return
        }

        do {
            try pool.write { db in
                try messages.forEach { try $0.delete(db) }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "cache db deletion error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db deletion error: \(error.localizedDescription)")
        }
    }
}

// MARK: - DraftsCacheServiceProtocol

extension CacheService {
    func retrieveDraft(channelID: String, messageGUID: String) -> MessageDraft? {
        self.retrieveDraftsInternal(channelID: channelID, messageGUID: messageGUID).first
    }

    func retrieveDrafts(channelID: String) -> [MessageDraft] {
        self.retrieveDraftsInternal(channelID: channelID)
    }

    private func retrieveDraftsInternal(channelID: String, messageGUID: String? = nil) -> [MessageDraft] {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return []
        }

        do {
            let drafts = try pool.read { db -> [MessageDraft]? in
                var query = MessageDraft
                    .filter(MessageDraft.Columns.channelID == channelID)

                if messageGUID != nil {
                    query = query.filter(MessageDraft.Columns.messageGUID == messageGUID)
                }

                return try query.fetchAll(db)
            } ?? []
            return drafts
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "cache db fetch error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db fetch error: \(error.localizedDescription)")
            return []
        }
    }

    func save(draft: MessageDraft) {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return
        }

        do {
            try pool.write { db in
                try draft.save(db)
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "cache db write error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db write error: \(error.localizedDescription)")
        }
    }

    func delete(draft: MessageDraft) {
        guard let pool = self.dbPool else {
            assertionFailure("Invalid db pool")
            return
        }

        do {
            _ = try pool.write { db in
                try draft.delete(db)
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "cache db write error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "cache db write error: \(error.localizedDescription)")
        }
    }
}

// MARK: - FilesCacheServiceProtocol

extension CacheService: FilesCacheServiceProtocol {
    func exists(cacheKey: String) -> URL? {
        self.filesCacheService.exists(cacheKey: cacheKey)
    }

    func exists(file: FileInfo) -> URL? {
        self.filesCacheService.exists(file: file)
    }

    func retrieve(file: FileInfo) -> Data? {
        self.filesCacheService.retrieve(file: file)
    }

    func save(file: FileInfo, data: Data) -> URL? {
        self.filesCacheService.save(file: file, data: data)
    }

    func retrieve(cacheKey: String) -> Data? {
        self.filesCacheService.retrieve(cacheKey: cacheKey)
    }

    func save(cacheKey: String, data: Data) -> URL? {
        self.filesCacheService.save(cacheKey: cacheKey, data: data)
    }

    func erase() {
        filesCacheService.erase()
    }
}

extension DatabasePool {

    public static func poolBy(clientID: String, cacheDirectory: URL?) -> DatabasePool? {
        guard
            let dbPath = Self.dbPath(for: clientID, cacheDirectory: cacheDirectory),
            let pool = try? DatabasePool(path: dbPath) else {
            assertionFailure("unable to initialize sqlite db file")
            return nil
        }
        log(sender: nil, "\(DatabasePool.self) store sqlite db cache in \(dbPath)")
        return pool
    }

    private static func dbPath(for clientID: String, cacheDirectory: URL?) -> String? {
        cacheDirectory?
            .appendingPathComponent("chat_cache_\(clientID).sqlite", isDirectory: false)
            .absoluteString
    }
}

final class FilesCacheService: FilesCacheServiceProtocol {
    private let cacheDirectory: URL

    init(cacheDirectory: URL?) {
        let directory = (cacheDirectory ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("files", isDirectory: true)

        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )

            self.cacheDirectory = directory
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self))  \(#function)",
                "details": "cache db write error",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            self.cacheDirectory = FileManager.default.temporaryDirectory
        }
    }

    func exists(file: FileInfo) -> URL? {
        exists(cacheKey: file.cacheKey)
    }

    func exists(cacheKey: String) -> URL? {
        let fileURL = self.cacheDirectory.appendingPathComponent(cacheKey)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }
    
    func retrieve(file: FileInfo) -> Data? {
        return retrieve(cacheKey: file.cacheKey)
    }

    func save(file: FileInfo, data: Data) -> URL? {
        save(cacheKey: file.cacheKey, data: data)
    }

    func retrieve(cacheKey: String) -> Data? {
        let fileURL = self.cacheDirectory.appendingPathComponent(cacheKey)
        guard FileManager.default.fileExists(atPath: fileURL.absoluteString) else {
            return try? Data(contentsOf: fileURL)
        }

        return nil
    }

    func save(cacheKey: String, data: Data) -> URL? {
        let fileURL = self.cacheDirectory.appendingPathComponent(cacheKey)

        do {
            try fileURL.createWithSubdirectoriesIfNeeded()
            try data.write(to: fileURL, options: .atomic)
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "files cache service: unable to write file! CacheKey: \(cacheKey)",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "files cache service: unable to write file!")
            return nil
        }

        return fileURL
    }

    internal func erase() {
        try? FileManager.default.removeItem(at: self.cacheDirectory)
    }
}

final class DummyCacheService: CacheServiceProtocol {
    func retrieveMessages(guids: [String]) -> [Message] { [] }
//    func oldestMessage(in channelID: String) -> Message? { nil }
    func retrieve(channelID: String, limit: Int, from: Int) -> [Message] { [] }
    func retrieve(channelID: String, limit: Int, offsetGUID: String?, requestOlderMessages: Bool) -> [Message] { [] }
    func retrieveLastMessages() -> [Message] { [] }
    func save(messages: [Message]) { }
    func delete(messages: [Message]) { }
    func retrieveDrafts(channelID: String) -> [MessageDraft] { [] }
    func retrieveDraft(channelID: String, messageGUID: String) -> MessageDraft? { nil }
    func save(draft: MessageDraft) { }
    func delete(draft: MessageDraft) { }

    func exists(cacheKey: String) -> URL? { nil }
    func exists(file: FileInfo) -> URL? { nil }
    func retrieve(file: FileInfo) -> Data? { nil }
    func save(file: FileInfo, data: Data) -> URL? {
        URL(fileURLWithPath: "dummy")
    }
    func retrieve(cacheKey: String) -> Data? { nil }
    func save(cacheKey: String, data: Data) -> URL? {
        URL(fileURLWithPath: "dummy")
    }
    func erase() { }
}
