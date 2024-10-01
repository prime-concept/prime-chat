import XCTest
@testable import ChatSDK

class APIClientTests: XCTestCase {

    var apiClient: APIClient!
    var authState: AuthStateProtocolMock!
    var config: URLSessionConfiguration!

    override func setUp() {
        super.setUp()
        let baseURL = URL(string: "example.com/retrieve")!

        config = .ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.protocolClasses = [
            URLProtocolApiClientRetrieveFailureMock.self,
            URLProtocolApiClientCreateFailureMock.self,
            URLProtocolApiClientUpdateFailureMock.self,
            URLProtocolApiClientMultipartFailureMock.self,
            URLProtocolApiClientDataFailureMock.self,
            URLProtocolApiClientDownloadFailureMock.self,

            URLProtocolApiClientRetrieveSuccessMock.self,
            URLProtocolApiClientCreateSuccessMock.self,
            URLProtocolApiClientUpdateSuccessMock.self,
            URLProtocolApiClientMultipartSuccessMock.self,
            URLProtocolApiClientDataSuccessMock.self,
            URLProtocolApiClientDownloadSuccessMock.self,
        ]

        authState = AuthStateProtocolMock()
        apiClient = APIClient(
            baseURL: baseURL,
            authState: authState,
            urlSessionConfiguration: config
        )
    }

    override func tearDown() {
        apiClient = nil
        authState = nil
        config = nil
        super.tearDown()
    }

    // MARK: - Retrieve

    func testRetrieveSuccess() {
        // Arrange
        let path = "testRetrieve"
        let expectation = expectation(description: "retrieve completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?

        let completion: APIResultCallback<DecodableModel> = { result in
            switch result {
            case .success(let httpResult):
                XCTAssertNotNil(httpResult.data)
            case .failure(let error):
                XCTFail("Retrieve failed with error: \(error)")
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.retrieve(
                path: path,
                parameters: Constants.parameters,
                headers: Constants.headers,
                decoder: JSONDecoder(),
                completion: completion
            )
            taskStateOriginally = task?.state
        } catch {
            XCTFail("Retrieve threw an error: \(error)")
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .running)
        XCTAssertTrue(task?.originalRequest?.url?.absoluteString.contains(path) == true)
        XCTAssertTrue(task?.originalRequest?.url?.query?.contains("key1=value1") == true)
        XCTAssertTrue(task?.originalRequest?.url?.query?.contains("key2=value2") == true)
        XCTAssertEqual(task?.originalRequest?.value(forHTTPHeaderField: "header1"), "value1")
        XCTAssertEqual(task?.originalRequest?.value(forHTTPHeaderField: "header2"), "value2")
    }

    func testRetrieveFailure() {
        // Arrange
        let path = "testRetrieveFailure"
        let expectation = expectation(description: "retrieve failure completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?
        var networkErrorDomain: String?

        let completion: APIResultCallback<DecodableModel> = { result in
            switch result {
            case .success:
                XCTFail("Retrieve succeeded unexpectedly")
            case .failure(let error):
                switch error {
                case .urlSession(let networkError):
                    networkErrorDomain = (networkError as NSError).domain
                default:
                    XCTFail("Download should threw an error: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.retrieve(
                path: path,
                parameters: [:],
                headers: [:],
                decoder: JSONDecoder(),
                completion: completion
            )
            taskStateOriginally = task?.state
        } catch {
            XCTFail("Retrieve threw an error: \(error)")
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .running)
        XCTAssertEqual(networkErrorDomain, "RestrictedContentException")
    }

    // MARK: - create

    func testCreateSuccess() {
        // Arrange
        let path = "testCreate"
        let expectation = expectation(description: "create completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?

        let completion: APIResultCallback<DecodableModel> = { result in
            switch result {
            case .success(let httpResult):
                XCTAssertNotNil(httpResult.data)
            case .failure(let error):
                XCTFail("Create failed with error: \(error)")
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.create(
                path: path,
                queryParameters: Constants.parameters,
                data: EncodableModel(),
                headers: Constants.headers,
                decoder: JSONDecoder(),
                encoder: JSONEncoder(),
                completion: completion
            )
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Create threw an error: \(error)")
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .running)
        XCTAssertTrue(task?.originalRequest?.url?.absoluteString.contains(path) == true)
        XCTAssertTrue(task?.originalRequest?.url?.query?.contains("key1=value1") == true)
        XCTAssertTrue(task?.originalRequest?.url?.query?.contains("key2=value2") == true)
        XCTAssertEqual(task?.originalRequest?.value(forHTTPHeaderField: "header1"), "value1")
        XCTAssertEqual(task?.originalRequest?.value(forHTTPHeaderField: "header2"), "value2")
    }

    func testCreateFailure() {
        // Arrange
        let path = "testCreateFailure"
        let expectation = expectation(description: "create failure completion")
        var networkErrorDomain: String?

        let completion: APIResultCallback<DecodableModel> = { result in
            switch result {
            case .success:
                XCTFail("Create succeeded unexpectedly")
            case .failure(let error):
                switch error {
                case .urlSession(let networkError):
                    networkErrorDomain = (networkError as NSError).domain
                default:
                    XCTFail("Download should threw an error: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Act
        do {
            let task = try apiClient.create(
                path: path,
                queryParameters: [:],
                data: EncodableModel(),
                headers: [:],
                decoder: JSONDecoder(),
                encoder: JSONEncoder(),
                completion: completion
            )
            XCTAssertNotNil(task)
        } catch {
            XCTFail("Create threw an error: \(error)")
        }

        // Assert
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertEqual(networkErrorDomain, "RestrictedContentException")
    }

    // MARK: - update

    func testUpdateSuccess() {
        // Arrange
        let path = "testUpdate"
        let expectation = expectation(description: "update completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?

        let completion: APIResultCallback<DecodableModel> = { result in
            switch result {
            case .success(let httpResult):
                XCTAssertNotNil(httpResult.data)
            case .failure(let error):
                XCTFail("Update failed with error: \(error)")
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.update(
                path: path,
                queryParameters: Constants.parameters,
                data: EncodableModel(),
                headers: Constants.headers,
                decoder: JSONDecoder(),
                encoder: JSONEncoder(),
                completion: completion
            )
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Update threw an error: \(error)")
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .running)
        XCTAssertTrue(task?.originalRequest?.url?.absoluteString.contains(path) == true)
        XCTAssertTrue(task?.originalRequest?.url?.query?.contains("key1=value1") == true)
        XCTAssertTrue(task?.originalRequest?.url?.query?.contains("key2=value2") == true)
        XCTAssertEqual(task?.originalRequest?.value(forHTTPHeaderField: "header1"), "value1")
        XCTAssertEqual(task?.originalRequest?.value(forHTTPHeaderField: "header2"), "value2")
    }

    func testUpdateFailure() {
        // Arrange
        let path = "testUpdateFailure"
        let expectation = expectation(description: "update failure completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?
        var networkErrorDomain: String?

        let completion: APIResultCallback<DecodableModel> = { result in
            switch result {
            case .success:
                XCTFail("Update succeeded unexpectedly")
            case .failure(let error):
                switch error {
                case .urlSession(let networkError):
                    networkErrorDomain = (networkError as NSError).domain
                default:
                    XCTFail("Download should threw an error: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.update(
                path: path,
                queryParameters: [:],
                data: EncodableModel(),
                headers: [:],
                decoder: JSONDecoder(),
                encoder: JSONEncoder(),
                completion: completion
            )
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Update threw an error: \(error)")
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .running)
        XCTAssertEqual(networkErrorDomain, "RestrictedContentException")
    }

    // MARK: - multipart

    func testMultipartSuccess() {
        // Arrange
        let path = "testMultipart"
        let expectation = expectation(description: "multipart completion")

        let completion: APIResultCallback<DecodableModel> = { result in
            switch result {
            case .success(let httpResult):
                XCTAssertNotNil(httpResult.data)
            case .failure(let error):
                XCTFail("Multipart failed with error: \(error)")
            }
            expectation.fulfill()
        }

        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?

        // Act
        do {
            task = try apiClient.multipart(
                path: path,
                filename: "test.jpg",
                mimeType: .imageJPG,
                data: Data(),
                headers: Constants.headers,
                timeout: nil,
                decoder: JSONDecoder(),
                progress: nil,
                completion: completion
            )
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Multipart threw an error: \(error)")
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .suspended)
        XCTAssertEqual(task?.originalRequest?.value(forHTTPHeaderField: "header1"), "value1")
        XCTAssertEqual(task?.originalRequest?.value(forHTTPHeaderField: "header2"), "value2")
    }

    func testMultipartFailure() {
        // Arrange
        let path = "testMultipartFailure"
        let expectation = expectation(description: "multipart failure completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?

        let completion: APIResultCallback<DecodableModel> = { result in
            switch result {
            case .success:
                XCTFail("Multipart succeeded unexpectedly")
            case .failure(let error):
                XCTAssertEqual(error, .unknown)
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.multipart(
                path: path,
                filename: "test.jpg",
                mimeType: .imageJPG,
                data: Data(),
                headers: [:],
                timeout: nil,
                decoder: JSONDecoder(),
                progress: nil,
                completion: completion
            )
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Multipart threw an error: \(error)")
        }

        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .suspended)
    }

    // MARK: - data

    func testDataSuccess() {
        // Arrange
        let path = "testData"
        let expectation = expectation(description: "data completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?

        let completion: RawResultCallback = { result in
            switch result {
            case .success(let dataResponse):
                XCTAssertNotNil(dataResponse.data)
                XCTAssertNotNil(dataResponse.response)
            case .failure(_):
                XCTFail("Data failed with error: (error)")
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.data(path: path, completion: completion)
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Data threw an error: \(error)")
        }

        // Assert
        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .suspended)
    }

    func testDataFailure() {
        // Arrange
        let path = "testDataFailure"
        let expectation = expectation(description: "data failure completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?

        let completion: RawResultCallback = { result in
            switch result {
            case .success:
                XCTFail("Data succeeded unexpectedly")
            case .failure(let error):
                XCTAssertEqual(error, .unknown)
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.data(path: path, completion: completion)
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Data threw an error: \(error)")
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .suspended)
    }

    // MARK: - download

    func testDownloadSuccess() {
        let path = "testDownload"
        let expectation = expectation(description: "download completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?

        let completion: DownloadCallback = { result in
            switch result {
            case .success(let url):
                XCTAssertNotNil(url)
            case .failure(let error):
                XCTFail("Download failed with error: \(error)")
            }
            expectation.fulfill()
        }

        do {
            task = try apiClient.download(path: path, progress: nil, completion: completion)
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Download threw an error: \(error)")
        }

        waitForExpectations(timeout: 5, handler: nil)

        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .suspended)
    }

    func testDownloadFailure() {
        // Arrange
        let path = "testDownloadFailure"
        let expectation = expectation(description: "download failure completion")
        var task: URLSessionTask?
        var taskStateOriginally: URLSessionTask.State?
        var networkErrorDomain: String?

        let completion: DownloadCallback = { result in
            switch result {
            case .success:
                XCTFail("Download succeeded unexpectedly")
            case .failure(let error):
                switch error {
                case .urlSession(let networkError):
                    networkErrorDomain = (networkError as NSError).domain
                default:
                    XCTFail("Download should threw an error: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Act
        do {
            task = try apiClient.download(path: path, progress: nil, completion: completion)
            taskStateOriginally = task?.state
            task?.resume()
        } catch {
            XCTFail("Download threw an error: \(error)")
        }
        waitForExpectations(timeout: 5, handler: nil)

        // Assert
        XCTAssertNotNil(task)
        XCTAssertEqual(taskStateOriginally, .suspended)
        XCTAssertEqual(networkErrorDomain, "RestrictedContentException")
    }
}

// MARK: - tools

private struct DecodableModel: Decodable {
    let id: Int
}

private struct EncodableModel: Encodable {
    let id: Int = 1
}

// MARK: - constants

private enum Constants {
    static let parameters: [String: String] = ["key1": "value1", "key2": "value2"]
    static let headers: [String: String] = ["header1": "value1", "header2": "value2"]
}
