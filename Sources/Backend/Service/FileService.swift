import Foundation

public protocol DataInitializable {
    /// Initializes an instance from the provided `Data`.
    ///
    /// - Parameter data: The `Data` used to initialize the instance.
    /// - Returns: An optional instance of the conforming type if initialization is successful, otherwise `nil`.
    init?(data: Data)
}

protocol FilesDownloadServiceProtocol: AnyObject {
    /// Downloads a file.
    ///
    /// - Parameters:
    ///   - file: Information about the file to be downloaded.
    ///   - skipCache: A Boolean indicating whether to skip the cache.
    ///   - completion: A closure that gets called with the downloaded `Data` or `nil` if the download fails.
    func download(
        file: FileInfo,
        skipCache: Bool,
        completion: @escaping (Data?) -> Void
    )

    /// Downloads a file with progress tracking.
    ///
    /// - Parameters:
    ///   - file: Information about the file to be downloaded.
    ///   - skipCache: A Boolean indicating whether to skip the cache.
    ///   - progress: A closure that gets called with the download progress.
    ///   - completion: A closure that gets called with the file URL or `nil` if the download fails.
    func download(
        file: FileInfo,
        skipCache: Bool,
        progress: @escaping ProgressCallback,
        completion: @escaping (URL?) -> Void
    )

    /// Downloads a file and decodes it into a specified type conforming to `DataInitializable`.
    ///
    /// - Parameters:
    ///   - file: Information about the file to be downloaded.
    ///   - skipCache: A Boolean indicating whether to skip the cache.
    ///   - onMainQueue: A Boolean indicating whether to execute the completion handler on the main queue.
    ///   - completion: A closure that gets called with the decoded object or `nil` if the download or decoding fails.
    func downloadAndDecode<T: DataInitializable>(
        file: FileInfo,
        skipCache: Bool,
        onMainQueue: Bool,
        completion: @escaping (T?) -> Void
    )

    /// Retrieves a cached file and decodes it into a specified type conforming to `DataInitializable`.
    ///
    /// - Parameter file: Information about the file to be retrieved from the cache.
    /// - Returns: An optional decoded object if the file is found in the cache, otherwise `nil`.
    func cached<T: DataInitializable>(file: FileInfo) -> T?
}

protocol FilesUploadServiceProtocol {
    /// Uploads a file immediately.
    ///
    /// - Parameters:
    ///   - filename: The name of the file to be uploaded.
    ///   - data: The `Data` representing the file's contents.
    ///   - mimeType: The MIME type of the file.
    ///   - completion: A closure that gets called with the result of the upload, containing either an array of `UploadedFile` or an error.
    func uploadImmediate(
        filename: String,
        data: Data,
        mimeType: APIClientMimeType,
        completion: @escaping (Result<[UploadedFile], Swift.Error>) -> Void
    )

    /// Uploads a file immediately with progress tracking.
    ///
    /// - Parameters:
    ///   - filename: The name of the file to be uploaded.
    ///   - data: The `Data` representing the file's contents.
    ///   - mimeType: The MIME type of the file.
    ///   - progress: A closure that gets called with the upload progress.
    ///   - completion: A closure that gets called with the result of the upload, containing either an array of `UploadedFile` or an error.
    func uploadImmediate(
        filename: String,
        data: Data,
        mimeType: APIClientMimeType,
        progress: @escaping ProgressCallback,
        completion: @escaping (Result<[UploadedFile], Swift.Error>) -> Void
    )
}

protocol FileServiceProtocol: FilesDownloadServiceProtocol, FilesUploadServiceProtocol {}

// MARK: - FileService

final class FileService: FileServiceProtocol {
    private static let queue = DispatchQueue(label: "FilesDownloadService.decode", qos: .userInitiated)
    private let storageClient: FileStorageClientProtocol
    private let filesCacheService: FilesCacheServiceProtocol

    // @v.kiryukhin: try to use NSCache

    private var dataCache = Cache<String, Data>()
    private var fileCache = Cache<String, Any>()
    private var urlCache = Cache<String, URL>()

    init(
        storageClient: FileStorageClientProtocol,
        filesCacheService: FilesCacheServiceProtocol
    ) {
        self.storageClient = storageClient
        self.filesCacheService = filesCacheService

        Notification.onReceive(.shouldClearCache, .loggedOut) { [weak self] _ in
            self?.clearCache()
        }
    }

    func download(
        file: FileInfo,
        skipCache: Bool,
        progress: @escaping ProgressCallback,
        completion: @escaping (URL?) -> Void
    ) {
        let cacheKey = file.cacheKey
        if !skipCache, let cached = self.urlCache[cacheKey] {
            return completion(cached)
        }

        do {
            try _ = self.storageClient.download(file: file, progress: progress) { [weak self] response in
                switch response {
                case .success(let fileURL):
                    guard let data = try? Data(contentsOf: fileURL) else {
                        completion(nil)
                        return
                    }

                    try? FileManager.default.removeItem(atPath: fileURL.path)

                    let url = self?.filesCacheService.save(cacheKey: cacheKey, data: data)
                    if let url = url {
                        self?.urlCache[cacheKey] = url
                    }
                    completion(url)

                case .failure:
                    completion(nil)
                }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) download",
                "details": "FILE: \(file.remotePath ?? "NULL_PATH!")",
                "error": error
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
            log(sender: self, "[FILE SERVICE] \(#function) (0) Error loading file: \(userInfo)")

            completion(nil)
        }
    }

    func download(file: FileInfo, skipCache: Bool, completion: @escaping (Data?) -> Void) {
        let cacheKey = file.cacheKey

        if !skipCache {
            if let inMemoryCached = self.dataCache[cacheKey] {
                return completion(inMemoryCached)
            }

            if let onDiskCached: Data = self.filesCacheService.retrieve(file: file) {
                self.dataCache[cacheKey] = onDiskCached
                log(sender: self, "files service: file \(cacheKey) found in disk cache, return cached data")
                return completion(onDiskCached)
            }
        }

        do {
            try _ = self.storageClient.download(file: file) { [weak self] response in
                guard let self else { return }

                switch response {
                case .success(let result):
                    self.dataCache[cacheKey] = result.data
                    self.filesCacheService.save(file: file, data: result.data)
                    
                    completion(result.data)
                    
                case .failure(let error):
                    let userInfo: [String: Any] = [
                        "sender": "\(type(of: self)) \(#function)",
                        "details": "[FILE SERVICE] (1) Error loading file: \(file)",
                        "error": error
                    ]
                    NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
                    
                    log(sender: self, "[FILE SERVICE] (1) Error loading file: \(file) \(error)")
                    completion(nil)
                }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "details": "[FILE SERVICE] (2) Error loading file: \(file)",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, "[FILE SERVICE] (2) Error loading file: \(file)")
            completion(nil)
        }
    }

    func cached<T: DataInitializable>(file: FileInfo) -> T? {
        let cacheKey = file.cacheKey

        if let data = self.dataCache[cacheKey] {
            return T(data: data)
        }

        if let data: Data = self.filesCacheService.retrieve(file: file) {
            self.dataCache[cacheKey] = data
            log(sender: self, "files service: file \(cacheKey) found in disk cache, return cached data")
            return T(data: data)
        }

        return nil
    }

    /// Download and decode data on given queue and run `completion` with result on main queue
    func downloadAndDecode<T: DataInitializable>(
        file: FileInfo,
        skipCache: Bool,
        onMainQueue: Bool,
        completion: @escaping (T?) -> Void
    ) {
        let cacheKey = file.cacheKey

        if !skipCache {
            if let data = self.dataCache[cacheKey] {
                return completion(T(data: data))
            }

            if let data: Data = self.filesCacheService.retrieve(file: file) {
                self.dataCache[cacheKey] = data
                log(sender: self, "files service: file \(cacheKey) found in disk cache, return cached data")
                return completion(T(data: data))
            }
        }

        self.download(file: file, skipCache: skipCache) { [weak self] data in
            guard let data else {
                return completion(nil)
            }

            let queue = onMainQueue ? DispatchQueue.main : Self.queue
            queue.async {
                let file = T(data: data)
                file.flatMap { self?.fileCache[cacheKey] = $0 }

                if !onMainQueue {
                    DispatchQueue.main.async {
                        completion(file)
                    }
                } else {
                    completion(file)
                }
            }
        }
    }

    func uploadImmediate(
        filename: String,
        data: Data,
        mimeType: APIClientMimeType,
        completion: @escaping (Result<[UploadedFile], Swift.Error>) -> Void
    ) {
        do {
            _ = try self.storageClient.uploadSync(
                data: data,
                filename: filename,
                mimeType: mimeType
            ) { result in
                switch result {
                case .success(let response):
                    if 200...299 ~= response.httpStatusCode {
                        if case .result(let files) = response.data {
                            completion(.success(files))
                        } else {
                            completion(.failure(Error.unrecognizedResult))
                        }
                    } else {
                        completion(.failure(Error.serverError(code: response.httpStatusCode)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) uploadImmediate 1",
                "details": "\(#function) uploadingFailed",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            completion(.failure(Error.uploadingFailed))
        }
    }

    func uploadImmediate(
        filename: String,
        data: Data,
        mimeType: APIClientMimeType,
        progress: @escaping ProgressCallback,
        completion: @escaping (Result<[UploadedFile], Swift.Error>) -> Void
    ) {
        do {
            _ = try self.storageClient.uploadSync(
                data: data,
                filename: filename,
                mimeType: mimeType,
                progress: progress
            ) { result in
                switch result {
                case .success(let response):
                    if 200...299 ~= response.httpStatusCode {
                        if case .result(let files) = response.data {
                            completion(.success(files))
                        } else {
                            completion(.failure(Error.unrecognizedResult))
                        }
                    } else {
                        completion(.failure(Error.serverError(code: response.httpStatusCode)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self))  uploadImmediate 2",
                "details": "\(#function) uploadingFailed",
                "error": error
            ]
            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
            
            completion(.failure(Error.uploadingFailed))
        }
    }

    // MARK: - Error

    enum Error: Swift.Error {
        case uploadingFailed
        case unrecognizedResult
        case serverError(code: Int)
    }
}

// MARK: - Private

private extension FileService {

    @objc
    func clearCache() {
        self.dataCache.removeAllObjects()
        self.fileCache.removeAllObjects()
        self.urlCache.removeAllObjects()
    }

}
