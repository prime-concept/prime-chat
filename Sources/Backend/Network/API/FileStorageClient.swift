import Foundation

protocol FileStorageClientProtocol: AnyObject, AutoMockable {
    func uploadSync(
        data: Data,
        filename: String,
        mimeType: APIClientMimeType,
        completion: @escaping APIResultCallback<FilesUploadResponse>
    ) throws -> URLSessionTask

    func uploadSync(
        data: Data,
        filename: String,
        mimeType: APIClientMimeType,
        progress: @escaping ProgressCallback,
        completion: @escaping APIResultCallback<FilesUploadResponse>
    ) throws -> URLSessionTask

    func download(file: FileInfo, completion: @escaping RawResultCallback) throws -> URLSessionTask
    func download(
        file: FileInfo,
        progress: @escaping ProgressCallback,
        completion: @escaping DownloadCallback
    ) throws -> URLSessionTask
}

final class FileStorageClient: APIClient {
    private static let basePath = "/files"
    private static let basePathAsync = "/files/async"

    private static let decoder = ChatJSONDecoder()

    private let uploadOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "FileStorageClient.uploadOperationQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    private let downloadOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "FileStorageClient.downloadOperationQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    required init(
        baseURL: URL,
        authState: AuthStateProtocol,
        urlSessionConfiguration: URLSessionConfiguration
    ) {
        super.init(
            baseURL: baseURL,
            authState: authState,
            urlSessionConfiguration: urlSessionConfiguration
        )
    }
}

extension FileStorageClient: FileStorageClientProtocol {

    func uploadSync(
        data: Data,
        filename: String,
        mimeType: APIClientMimeType,
        completion: @escaping APIResultCallback<FilesUploadResponse>
    ) throws -> URLSessionTask {
        let operation = TaskOperation()

        let completionOnOperation: APIResultCallback<FilesUploadResponse> = { result in
            operation.finish()
            completion(result)
        }

        let task = try self.multipart(
            path: Self.basePath,
            filename: filename,
            mimeType: mimeType,
            data: data,
            decoder: Self.decoder,
            completion: completionOnOperation
        )

        operation.task = task
        self.uploadOperationQueue.addOperation(operation)

        return task
    }

    func uploadSync(
        data: Data,
        filename: String,
        mimeType: APIClientMimeType,
        progress: @escaping ProgressCallback,
        completion: @escaping APIResultCallback<FilesUploadResponse>
    ) throws -> URLSessionTask {
        let operation = TaskOperation()

        let completionOnOperation: APIResultCallback<FilesUploadResponse> = { result in
            operation.finish()
            completion(result)
        }

        let task = try self.multipart(
            path: Self.basePath,
            filename: filename,
            mimeType: mimeType,
            data: data,
            timeout: 1 * 60 * 60, // Let's allow user to upload 1-hour-heavy things
            decoder: Self.decoder,
            progress: progress,
            completion: completionOnOperation
        )

        operation.task = task
        self.uploadOperationQueue.addOperation(operation)

        return task
    }

    func download(file: FileInfo, completion: @escaping RawResultCallback) throws -> URLSessionTask {
        let path = [Self.basePath, file.privacy.rawValue, file.uuid].joined(separator: "/")
        let operation = TaskOperation()

        let completionOnOperation: RawResultCallback = { result in
            operation.finish()
            completion(result)
        }

        let task = try self.data(path: path, completion: completionOnOperation)

        operation.task = task
        self.downloadOperationQueue.addOperation(operation)

        return task
    }

    func download(
        file: FileInfo,
        progress: @escaping ProgressCallback,
        completion: @escaping DownloadCallback
    ) throws -> URLSessionTask {
        let path = [Self.basePath, file.privacy.rawValue, file.uuid].joined(separator: "/")
        let operation = TaskOperation()

        let completionOnOperation: DownloadCallback = { result in
            operation.finish()
            completion(result)
        }

        let task = try self.download(path: path, progress: progress, completion: completionOnOperation)

        operation.task = task
        self.downloadOperationQueue.addOperation(operation)

        return task
    }
}
