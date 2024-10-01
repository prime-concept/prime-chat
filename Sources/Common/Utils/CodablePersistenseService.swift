import Foundation

class CodablePersistenseService {
    static let shared = CodablePersistenseService()

    private lazy var cacheRootURL = try? FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    ).appendingPathComponent("codable_cache")

    init() {
        Notification.onReceive(.loggedOut, .shouldClearCache) { [weak self] _ in
            self?.clearCache()
        }
    }

    func delete(fileName name: String) -> Swift.Error? {
        let filePath = self.filePath(for: name)

        do {
            if FileManager.default.fileExists(atPath: filePath) {
                try FileManager.default.removeItem(atPath: filePath)
            }
            return nil
        } catch {
            return error
        }
    }

    @discardableResult
    func write<T: Encodable>(_ codable: T, fileName name: String) -> Swift.Error? {
        let filePath = self.filePath(for: name)
        return self.write(codable, explicitFilePath: filePath)
    }

    @discardableResult
    func write<T: Encodable>(_ codable: T, explicitFilePath path: String) -> Swift.Error? {
        let fileURL = URL(fileURLWithPath: path)
        let string = (try? codable.toJSONString()) as? String

        guard let string = string, let data = string.data(using: .utf8) else {
            return nil
        }

        do {
            let directoryPath = fileURL.deletingLastPathComponent()
                .absoluteString
                .withSanitizedFileSchema

            if FileManager.default.fileExists(atPath: directoryPath),
               FileManager.default.fileExists(atPath: path) {
                try data.write(to: fileURL, options: .atomic)
                return nil
            }

            try FileManager.default.createDirectory(
                atPath: directoryPath,
                withIntermediateDirectories: true
            )

            FileManager.default.createFile(atPath: path, contents: data)
            return nil
        } catch {
            return error
        }
    }

    func read<T: Decodable>(from fileName: String) -> T? {
        let path = self.filePath(for: fileName)
        return self.read(explicitFilePath: path)
    }

    func read<T: Decodable>(explicitFilePath path: String) -> T? {
        let json = (try? String(contentsOfFile: path)) ?? ""
        guard let data = json.data(using: .utf8),
              let instance: T = data.decodeJSON() else {
            return nil
        }

        return instance
    }

    private func filePath(for name: String) -> String {
        var path = self.cacheRootURL?.absoluteString ?? ""

        path.append("/\(name).json")
        path = path.withSanitizedFileSchema

        return path
    }

    @objc
    private func clearCache() {
        guard let path = self.cacheRootURL?.absoluteString else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: path.withSanitizedFileSchema)
        } catch {
        }
    }
}

private extension String {
    var withSanitizedFileSchema: String {
        self.replacingOccurrences(of: "^file:\\/+", with: "/", options: .regularExpression)
    }
}

extension Encodable {
    var jsonData: Data? {
        try? JSONEncoder().encode(self)
    }

    var jsonString: String? {
        jsonString(encoding: .utf8)
    }

    func jsonString(encoding: String.Encoding = .utf8) -> String? {
        guard let data = self.jsonData else {
            return nil
        }

        return String(data: data, encoding: encoding)
    }

    @discardableResult
    func write(to fileName: String) -> Swift.Error? {
        CodablePersistenseService.shared.write(self, fileName: fileName)
    }
}

extension Decodable {
    static func read(from fileName: String) -> Self? {
        CodablePersistenseService.shared.read(from: fileName)
    }

    static func read(explicitFilePath path: String) -> Self? {
        CodablePersistenseService.shared.read(explicitFilePath: path)
    }
}

extension Data {
    func decodeJSON<T: Decodable>() -> T? {
        try? JSONDecoder().decode(T.self, from: self)
    }
}

extension String {
    func decodeJSON<T: Decodable>() -> T? {
        let data = self.data(using: .utf8)
        return data?.decodeJSON()
    }
}

extension Encodable {
    func toDictionary(_ encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try encoder.encode(self)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let json = object as? [String: Any] else {
            let context = DecodingError.Context(
                codingPath: [],
                debugDescription: "Deserialized object is not a dictionary"
            )
            throw DecodingError.typeMismatch(type(of: object), context)
        }
        return json
    }

    /// Converting object to postable JSON
    func toJSONString(_ encoder: JSONEncoder = JSONEncoder()) throws -> NSString {
        let data = try encoder.encode(self)
        let result = String(decoding: data, as: UTF8.self)
        return NSString(string: result)
    }
}
