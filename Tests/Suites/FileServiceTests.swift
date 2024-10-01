import XCTest
@testable import ChatSDK

class FileServiceTests: XCTestCase {
    var sutFileService: FileService!
    var storageClientMock: FileStorageClientProtocolMock!
    var cacheServiceMock: FilesCacheServiceProtocolMock!

    override func setUp() {
        super.setUp()
        storageClientMock = FileStorageClientProtocolMock()
        cacheServiceMock = FilesCacheServiceProtocolMock()
        sutFileService = FileService(storageClient: storageClientMock, filesCacheService: cacheServiceMock)
    }

    override func tearDown() {
        sutFileService = nil
        storageClientMock = nil
        cacheServiceMock = nil
        NotificationCenter.default.removeObserver(self, name: .chatSDKDidEncounterError, object: nil)
        super.tearDown()
    }

    // MARK: - download file

    func testDownloadFileSuccess() {
        // Arrange
        let fileInfo = FileInfo(uuid: "1", remotePath: "path/to/file")
        let urlRequest = URLRequest(url: URL(string: "example.com/files")!)
        let session = URLSession(configuration: .default)

        var fileData: Data?

        storageClientMock.stubbedDownloadResult = session.dataTask(with: urlRequest)

        let expectation = expectation(description: "download file")

        // Act
        sutFileService.download(file: fileInfo, skipCache: true) { data in
            fileData = data
            expectation.fulfill()
        }

        storageClientMock.invokedDownloadParameters?
            .completion(
                .success((
                    data: Constants.fileContent,
                    response: URLResponse()
                ))
            )

        waitForExpectations(timeout: 1.0)

        // Assert
        XCTAssertEqual(Constants.fileContent, fileData)
    }

    func testDownloadFileFailure() {
        // Arrange
        let fileInfo = FileInfo(uuid: "1", remotePath: "path/to/file")
        let urlRequest = URLRequest(url: URL(string: "example.com/files")!)
        let session = URLSession(configuration: .default)
        var fileData: Data?
        var userInfo: [String: Any] = [:]

        storageClientMock.stubbedDownloadResult = session.dataTask(with: urlRequest)

        let expectation = expectation(description: "download file")
        expectation.expectedFulfillmentCount = 2

        // Act
        NotificationCenter.default.addObserver(forName: .chatSDKDidEncounterError, object: nil, queue: .main) { notification in
            userInfo = notification.userInfo as? [String: Any] ?? [:]
            expectation.fulfill()
        }

        sutFileService.download(file: fileInfo, skipCache: true) { data in
            fileData = data
            expectation.fulfill()
        }

        storageClientMock.invokedDownloadParameters?
            .completion(
                .failure(APIClient.NetworkError.unknown)
            )

        waitForExpectations(timeout: 100.0)

        // Assert
        XCTAssertNil(fileData)
        XCTAssertNotNil(userInfo["error"])
        XCTAssertEqual(userInfo["error"] as? APIClient.NetworkError, APIClient.NetworkError.unknown)
        XCTAssertEqual(userInfo["details"] as? String, """
        [FILE SERVICE] (1) Error loading file: FileInfo(uuid: \"1\", privacy: ChatSDK.FileInfo.Privacy.private, \
        remotePath: Optional(\"path/to/file\"), fileName: nil, defaultExtension: nil, pathInCache: nil)
        """
        )
    }

    func testDownloadFileSuccessWithCache() {
        // Arrange
        let fileInfo = FileInfo(uuid: "1", remotePath: "path/to/file")
        let urlRequest = URLRequest(url: URL(string: "example.com/files")!)
        let session = URLSession(configuration: .default)

        var fileData: Data?

        storageClientMock.stubbedDownloadResult = session.dataTask(with: urlRequest)

        let expectation = expectation(description: "download file")

        // Act
        sutFileService.download(file: fileInfo, skipCache: true) { _ in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sutFileService.download(file: fileInfo, skipCache: false) { data in
                fileData = data
                expectation.fulfill()
            }
        }

        storageClientMock.invokedDownloadParameters?
            .completion(
                .success((
                    data: Constants.fileContent,
                    response: URLResponse()
                ))
            )

        waitForExpectations(timeout: 1.0)

        // Assert
        XCTAssertEqual(Constants.fileContent, fileData)
        XCTAssertFalse(cacheServiceMock.invokedRetrieveFile)
    }

    // MARK: - download file and decode

    func testDownloadAndDecodeFileSuccess() {
        // Arrange
        let fileInfo = FileInfo(remotePath: "path/to/file")
        let urlRequest = URLRequest(url: URL(string: "example.com/files")!)
        let session = URLSession(configuration: .default)
        storageClientMock.stubbedDownloadResult = session.dataTask(with: urlRequest)
        var decoded: TestData?
        let expectation = expectation(description: "Download and decode file")

        // Act
        sutFileService.downloadAndDecode(file: fileInfo!, skipCache: true, onMainQueue: true) { decodedData in
            decoded = decodedData
            expectation.fulfill()
        }

        storageClientMock.invokedDownloadParameters?
            .completion(
                .success((
                    data: Constants.fileContent,
                    response: URLResponse()
                ))
            )

        waitForExpectations(timeout: 2.0, handler: nil)

        // Assert
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.content, "file content")
    }

    func testDownloadAndDecodeCachedFileSuccess() {
        // Arrange
        let fileInfo = FileInfo(remotePath: "path/to/file")
        let urlRequest = URLRequest(url: URL(string: "example.com/files")!)
        let session = URLSession(configuration: .default)
        storageClientMock.stubbedDownloadResult = session.dataTask(with: urlRequest)
        var decoded: TestData?
        let expectation = expectation(description: "Download and decode file")

        // Act
        sutFileService.downloadAndDecode(file: fileInfo!, skipCache: true, onMainQueue: true) { (data: TestData?) in }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sutFileService.downloadAndDecode(file: fileInfo!, skipCache: false, onMainQueue: true) { decodedData in
                decoded = decodedData
                expectation.fulfill()
            }
        }

        storageClientMock.invokedDownloadParameters?
            .completion(
                .success((
                    data: Constants.fileContent,
                    response: URLResponse()
                ))
            )

        waitForExpectations(timeout: 2.0, handler: nil)

        // Assert
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.content, "file content")
        XCTAssertFalse(cacheServiceMock.invokedRetrieveFile)
    }

    // MARK: - upload

    func testUploadFileSuccess() {
        // Arrange
        let mimeType = APIClientMimeType.plain
        let uploadedFiles = [UploadedFile(
            name: "",
            path: "",
            privacy: UploadedFile.Privacy.private,
            uuid: "",
            checksum: nil,
            type: "",
            error: nil
        )]
        let urlRequest = URLRequest(url: URL(string: "example.com/files")!)
        let session = URLSession(configuration: .default)
        storageClientMock.stubbedUploadSyncResult = session.dataTask(with: urlRequest)
        var result: Result<[UploadedFile], Error> = .failure(APIClient.NetworkError.unknown)
        let expectation = expectation(description: "Upload file")

        // Act
        sutFileService.uploadImmediate(
            filename: Constants.filename,
            data: Constants.fileContent,
            mimeType: mimeType
        ) { rez in
            result = rez
            expectation.fulfill()
        }

        storageClientMock.invokedUploadSyncParameters?.completion(
            .success(.init(httpStatusCode: 200, data: .result(uploadedFiles)))
        )
        waitForExpectations(timeout: 2.0, handler: nil)

        // Assert
        switch result {
        case .success(let files):
            XCTAssertEqual(files, uploadedFiles)
        case .failure:
            XCTFail("Upload should succeed")
        }
    }

    func testUploadFileFailure() {
        // Arrange

        let mimeType = APIClientMimeType.plain
        let uploadedFiles = [UploadedFile(
            name: "",
            path: "",
            privacy: UploadedFile.Privacy.private,
            uuid: "",
            checksum: nil,
            type: "",
            error: nil
        )]
        let urlRequest = URLRequest(url: URL(string: "example.com/files")!)
        let session = URLSession(configuration: .default)
        storageClientMock.stubbedUploadSyncResult = session.dataTask(with: urlRequest)
        var result: Result<[UploadedFile], Error> = .failure(APIClient.NetworkError.unknown)
        let expectation = expectation(description: "Upload file")

        // Act
        sutFileService.uploadImmediate(
            filename: Constants.filename,
            data: Constants.fileContent,
            mimeType: mimeType
        ) { rez in
            result = rez
            expectation.fulfill()
        }

        storageClientMock.invokedUploadSyncParameters?.completion(
            .failure(APIClient.NetworkError.unknown)
        )
        waitForExpectations(timeout: 2.0, handler: nil)

        // Assert
        switch result {
        case .success:
            XCTFail("Upload should fail")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }

    // MARK: - upload with progress

    func testUploadFileWithProgress() {
        // Arrange
        let mimeType = APIClientMimeType.plain
        let uploadedFiles = [UploadedFile(
            name: "",
            path: "",
            privacy: UploadedFile.Privacy.private,
            uuid: "",
            checksum: nil,
            type: "",
            error: nil
        )]
        let urlRequest = URLRequest(url: URL(string: "https://example.com/files")!)
        let session = URLSession(configuration: .default)
        storageClientMock.stubbedUploadSyncDataResult = session.dataTask(with: urlRequest)
        var result: Result<[UploadedFile], Error> = .failure(APIClient.NetworkError.unknown)
        let expectation = expectation(description: "Upload file with progress")
        var progressUpdates: [Float] = []
        let expectedProgressUpdates: [Float] = [0.0, 0.5, 1.0]

        // Act
        sutFileService.uploadImmediate(
            filename: Constants.filename,
            data: Constants.fileContent,
            mimeType: mimeType,
            progress: { progress in
                progressUpdates.append(progress)
            },
            completion: { rez in
                result = rez
                expectation.fulfill()
            }
        )

        storageClientMock.invokedUploadSyncDataParameters?.progress(0.0)
        storageClientMock.invokedUploadSyncDataParameters?.progress(0.5)
        storageClientMock.invokedUploadSyncDataParameters?.progress(1.0)
        storageClientMock.invokedUploadSyncDataParameters?.completion(
            .success(.init(httpStatusCode: 200, data: .result(uploadedFiles)))
        )
        waitForExpectations(timeout: 2.0, handler: nil)

        // Assert
        XCTAssertEqual(progressUpdates, expectedProgressUpdates)
        switch result {
        case .success(let files):
            XCTAssertEqual(files, uploadedFiles)
        case .failure:
            XCTFail("Upload should succeed")
        }
    }

    // MARK: - cached

    func testGetCached() {
        // Arrange
        let fileInfo = FileInfo(uuid: "1", remotePath: "path/to/file")
        let urlRequest = URLRequest(url: URL(string: "example.com/files")!)
        let session = URLSession(configuration: .default)
        let expectation = expectation(description: "Upload file with progress")
        var fileData: Data?

        storageClientMock.stubbedDownloadResult = session.dataTask(with: urlRequest)

        // Act
        sutFileService.download(file: fileInfo, skipCache: true) { data in
            fileData = data
            expectation.fulfill()
        }

        storageClientMock.invokedDownloadParameters?
            .completion(
                .success((
                    data: Constants.fileContent,
                    response: URLResponse()
                ))
            )

        let cachedData: TestData? = sutFileService.cached(file: fileInfo)

        waitForExpectations(timeout: 2.0, handler: nil)

        // Assert
        XCTAssertEqual(Constants.fileContent, fileData)
    }
}

private extension FileServiceTests {
    enum Constants {
        static let filename = "testFile.txt"
        static let fileContent = "file content".data(using: .utf8)!
    }

    struct TestData: DataInitializable {
        let content: String

        init?(data: Data) {
            guard let content = String(data: data, encoding: .utf8) else {
                return nil
            }
            self.content = content
        }
    }
}
