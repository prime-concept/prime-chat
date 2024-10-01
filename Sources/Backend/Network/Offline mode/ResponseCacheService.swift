import Foundation
import CommonCrypto

extension Notification.Name {
    static let loggedIn = Notification.Name("loggedIn")
    static let loggedOut = Notification.Name("loggedOut")
    static let shouldClearCache = Notification.Name("shouldClearCache")
}

/// A protocol for managing cached data corresponding to network responses
protocol ResponseCacheServiceProtocol {

    /// Stores the provided data in the cache, associating it with the given URL and parameters
    ///
    /// - Parameters:
    ///   - data: The `Data` object that needs to be cached
    ///   - url: An optional `URL` representing the endpoint associated with the data
    ///   - parameters: An optional dictionary of parameters that might be used to further identify or categorize the cached data
    func write(data: Data, for url: URL?, parameters: [String: Any]?)

    /// Retrieves the cached data associated with the given URL and parameters, if it exists
    ///
    /// - Parameters:
    ///   - url: A `URL` representing the endpoint for which the cached data is being requested
    ///   - parameters: An optional dictionary of parameters that might be used to refine the search for the cached data
    /// - Returns: An optional `Data` object, which is the cached data associated with the given URL and parameters, if it exists
    func data(for url: URL, parameters: [String: Any]?) -> Data?
}
final class ResponseCacheService: ResponseCacheServiceProtocol {
    static let shared = ResponseCacheService()

    private lazy var cacheRootURL = try? FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    ).appendingPathComponent("response_cache")

    init() {
        Notification.onReceive(.shouldClearCache, .loggedOut) { [weak self] _ in
            self?.clearCache()
        }
    }

    func write(data: Data, for url: URL?, parameters: [String: Any]?) {
        guard let url = url, let data = data.aesEncrypt(key: "e3b0c44298fc1c149afbf4c8996fb92") else {
            return
        }

        let filePath = self.filePath(for: url, parameters: parameters)
        let fileURL = URL(fileURLWithPath: filePath)

        do {
            let directoryPath = fileURL.deletingLastPathComponent()
                .absoluteString
                .withSanitizedFileSchema

            if FileManager.default.fileExists(atPath: directoryPath),
               FileManager.default.fileExists(atPath: filePath) {
                try data.write(to: fileURL, options: .atomic)
                return
            }

            try FileManager.default.createDirectory(
                atPath: directoryPath,
                withIntermediateDirectories: true
            )

            FileManager.default.createFile(atPath: filePath, contents: data)
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "error": error
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, error)
        }
    }

    func data(for url: URL, parameters: [String: Any]?) -> Data? {
        let filePath = self.filePath(for: url, parameters: parameters)
        let fileURL = URL(fileURLWithPath: filePath)

        do {
            return try Data(contentsOf: fileURL).aesDecrypt(key: "e3b0c44298fc1c149afbf4c8996fb92")
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "error": error
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, error)
            return nil
        }
    }
}

// MARK: - private methods

private extension ResponseCacheService {
    func filePath(for url: URL, parameters: [String: Any]? = nil) -> String {
        var path = self.cacheRootURL?.absoluteString ?? ""

        url.host.flatMap { host in
            path.append("/")
            path.append(host.replacingOccurrences(of: ".", with: "/"))
        }

        path.append(url.path)

        if let sha256 = self.pathFragmentFrom(query: url.query)?.sha256 {
            path.append("/")
            path.append(sha256)
        }

        let tLessParameters = parameters?.filter { key, _ in key != "t" }
        if let sha256 = tLessParameters?.orderedStringRepresentation.sha256 {
            path.append("/")
            path.append(sha256)
        }

        path.append("/Data.dat")

        path = path.withSanitizedFileSchema

        return path
    }

    func pathFragmentFrom(query: String?) -> String? {
        guard let query = query else {
            return nil
        }

        let queryComponents = query.split(separator: "&").map { String($0) }
        var queryDictionary = [String: String]()

        for component in queryComponents {
            let pair = component.split(separator: "=").map { String($0) }
            if pair.count != 2 {
                continue
            }
            queryDictionary[pair[0]] = pair[1]
        }

        let tLessDictionary = queryDictionary.filter { key, _ in key != "t" }
        let result = "/" + tLessDictionary.orderedStringRepresentation.sha256

        return result
    }

    @objc
    func clearCache() {
        guard let path = self.cacheRootURL?.absoluteString else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: path.withSanitizedFileSchema)
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "error": error
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
            
            log(sender: self, error)
        }
    }
}

// MARK: - private extensions

private extension String {
    var withSanitizedFileSchema: String {
        self.replacingOccurrences(of: "^file:\\/+", with: "/", options: .regularExpression)
    }
}
