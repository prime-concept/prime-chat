import Foundation

class FileStorageClientProtocolMock: FileStorageClientProtocol {

    var invokedUploadSync = false
    var invokedUploadSyncCount = 0
    var invokedUploadSyncParameters: (data: Data, filename: String, mimeType: APIClientMimeType, completion: APIResultCallback<FilesUploadResponse>)?
    var invokedUploadSyncParametersList = [(data: Data, filename: String, mimeType: APIClientMimeType, completion: APIResultCallback<FilesUploadResponse>)]()
    var stubbedUploadSyncError: Error?
    var stubbedUploadSyncResult: URLSessionTask!

    func uploadSync(
        data: Data,
        filename: String,
        mimeType: APIClientMimeType,
        completion: @escaping APIResultCallback<FilesUploadResponse>
    ) throws -> URLSessionTask {
        invokedUploadSync = true
        invokedUploadSyncCount += 1
        invokedUploadSyncParameters = (data, filename, mimeType, completion)
        invokedUploadSyncParametersList.append((data, filename, mimeType, completion))
        if let error = stubbedUploadSyncError {
            throw error
        }
        return stubbedUploadSyncResult
    }

    var invokedUploadSyncData = false
    var invokedUploadSyncDataCount = 0
    var invokedUploadSyncDataParameters: (data: Data, filename: String, mimeType: APIClientMimeType, progress: ProgressCallback, completion: APIResultCallback<FilesUploadResponse>)?
    var invokedUploadSyncDataParametersList = [(data: Data, filename: String, mimeType: APIClientMimeType, progress: ProgressCallback, completion: APIResultCallback<FilesUploadResponse>)]()
    var stubbedUploadSyncDataError: Error?
    var stubbedUploadSyncDataResult: URLSessionTask!

    func uploadSync(
        data: Data,
        filename: String,
        mimeType: APIClientMimeType,
        progress: @escaping ProgressCallback,
        completion: @escaping APIResultCallback<FilesUploadResponse>
    ) throws -> URLSessionTask {
        invokedUploadSyncData = true
        invokedUploadSyncDataCount += 1
        invokedUploadSyncDataParameters = (data, filename, mimeType, progress, completion)
        invokedUploadSyncDataParametersList.append((data, filename, mimeType, progress, completion))
        if let error = stubbedUploadSyncDataError {
            throw error
        }
        return stubbedUploadSyncDataResult
    }

    var invokedDownload = false
    var invokedDownloadCount = 0
    var invokedDownloadParameters: (file: FileInfo, completion: RawResultCallback)?
    var invokedDownloadParametersList = [(file: FileInfo, completion: RawResultCallback)]()
    var stubbedDownloadError: Error?
    var stubbedDownloadResult: URLSessionTask!

    func download(file: FileInfo, completion: @escaping RawResultCallback) throws -> URLSessionTask {
        invokedDownload = true
        invokedDownloadCount += 1
        invokedDownloadParameters = (file, completion)
        invokedDownloadParametersList.append((file, completion))
        if let error = stubbedDownloadError {
            throw error
        }
        return stubbedDownloadResult
    }

    var invokedDownloadFile = false
    var invokedDownloadFileCount = 0
    var invokedDownloadFileParameters: (file: FileInfo, progress: ProgressCallback, completion: DownloadCallback)?
    var invokedDownloadFileParametersList = [(file: FileInfo, progress: ProgressCallback, completion: DownloadCallback)]()
    var stubbedDownloadFileError: Error?
    var stubbedDownloadFileResult: URLSessionTask!

    func download(
        file: FileInfo,
        progress: @escaping ProgressCallback,
        completion: @escaping DownloadCallback
    ) throws -> URLSessionTask {
        invokedDownloadFile = true
        invokedDownloadFileCount += 1
        invokedDownloadFileParameters = (file, progress, completion)
        invokedDownloadFileParametersList.append((file, progress, completion))
        if let error = stubbedDownloadFileError {
            throw error
        }
        return stubbedDownloadFileResult
    }
}
