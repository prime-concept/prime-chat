//
//  FileStorageClientTests.swift
//  empty_projectTests
//
//  Created by Hayk Kolozyan on 21.05.24.
//

import XCTest
@testable import ChatSDK

class FileStorageClientTests: XCTestCase {

    // MARK: - Positive Test Cases

    func testUploadSyncWithoutProgressSuccess() throws {
        // Arrange

        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolFileStorageClientSuccessMock.self]

        let authStateMock = AuthStateProtocolMock(
            accessToken: "testAccessToken",
            clientAppID: "testClientAppID",
            deviceID: "testDeviceID",
            wsUniqueID: "testWsUniqueID"
        )
        let sutFileClient = FileStorageClient(
            baseURL: url,
            authState: authStateMock,
            urlSessionConfiguration: config
        )

        let data = try XCTUnwrap("Test Data".data(using: .utf8))
        let mimeType = APIClientMimeType.plain
        let filename = "test.txt"
        let expectation = XCTestExpectation(description: "Upload completes successfully")

        // Act
        let task = try sutFileClient.uploadSync(data: data, filename: filename, mimeType: mimeType) { result in

            // Assert
            switch result {
            case let .success(response):
                XCTAssertNotNil(response)
            case let .failure(error):
                XCTFail("Upload failed with error: \(error)")
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        wait(for: [expectation], timeout: 5.0)
    }

    func testUploadSyncWithProgressSuccess() throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "example.com"))
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolFileStorageClientSuccessMock.self]

        let authStateMock = AuthStateProtocolMock(
            accessToken: "testAccessToken",
            clientAppID: "testClientAppID",
            deviceID: "testDeviceID",
            wsUniqueID: "testWsUniqueID"
        )
        let sutFileClient = FileStorageClient(
            baseURL: url,
            authState: authStateMock,
            urlSessionConfiguration: config
        )

        let data = try XCTUnwrap("Test Data".data(using: .utf8))
        let mimeType = APIClientMimeType.plain
        let filename = "test.txt"
        let expectation = XCTestExpectation(description: "Upload completes successfully")

        // Act
        let task = try sutFileClient.uploadSync(
            data: data,
            filename: filename,
            mimeType: mimeType,
            progress: { progress in
                XCTAssertTrue(abs(Int32(progress)) == data.count)
            }) { result in

            // Assert
            switch result {
            case let .success(response):
                XCTAssertNotNil(response)
            case let .failure(error):
                XCTFail("Upload failed with error: \(error)")
            }
                expectation.fulfill()
        }

        XCTAssertNotNil(task)
        wait(for: [expectation], timeout: 5.0)
    }

    func testDownloadWithoutProgressSuccess() throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolFileStorageClientSuccessMock.self]

        let authStateMock = AuthStateProtocolMock(
            accessToken: "testAccessToken",
            clientAppID: "testClientAppID",
            deviceID: "testDeviceID",
            wsUniqueID: "testWsUniqueID"
        )
        let sutFileClient = FileStorageClient(
            baseURL: url,
            authState: authStateMock,
            urlSessionConfiguration: config
        )

        let fileInfo = FileInfo(uuid: "test-uuid", privacy: .public)
        let expectation = XCTestExpectation(description: "Download completes successfully")

        // Act
        let task = try sutFileClient.download(file: fileInfo) { result in

            // Assert
            switch result {
            case let .success(data):
                XCTAssertNotNil(data)
            case let .failure(error):
                XCTFail("Download failed with error: \(error)")
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        wait(for: [expectation], timeout: 5.0)
    }

    func testDownloadWithProgressSuccess() throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolFileStorageClientSuccessMock.self]

        let authStateMock = AuthStateProtocolMock(
            accessToken: "testAccessToken",
            clientAppID: "testClientAppID",
            deviceID: "testDeviceID",
            wsUniqueID: "testWsUniqueID"
        )
        let sutFileClient = FileStorageClient(
            baseURL: url,
            authState: authStateMock,
            urlSessionConfiguration: config
        )

        let fileInfo = FileInfo(uuid: "test-uuid", privacy: .public)
        let expectation = XCTestExpectation(description: "Download completes successfully")

        // Act
        let task = try sutFileClient.download(
            file: fileInfo,
            progress: { progress in
                XCTAssertTrue(abs(Int32(progress)) == 27)
            }) { result in

                // Assert
                switch result {
                case let .success(url):
                    XCTAssertNotNil(url)
                case let .failure(error):
                    XCTFail("Download failed with error: \(error)")
                }
                expectation.fulfill()
            }

        XCTAssertNotNil(task)
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Negative Test Cases

    func testUploadSyncInvalidData() throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolFileStorageClientFailedMock.self]

        let authStateMock = AuthStateProtocolMock(
            accessToken: "testAccessToken",
            clientAppID: "testClientAppID",
            deviceID: "testDeviceID",
            wsUniqueID: "testWsUniqueID"
        )
        let sutFileClient = FileStorageClient(
            baseURL: url,
            authState: authStateMock,
            urlSessionConfiguration: config
        )

        let data = Data() // Empty data
        let mimeType = APIClientMimeType.plain
        let filename = "test.txt"
        let expectation = XCTestExpectation(description: "Upload fails with invalid data")

        // Act
        let task = try sutFileClient.uploadSync(
            data: data,
            filename: filename,
            mimeType: mimeType
        ) { result in

            // Assert
            switch result {
            case let .success(url):
                XCTAssertNotNil(url)
                XCTFail("Upload should not complete")
            case let .failure(error):
                XCTAssertEqual(error, APIClient.NetworkError.unknown)
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        wait(for: [expectation], timeout: 5.0)
    }

    // FIXME: - Need to correct
//    func testUploadSyncInvalidURL() throws {
//        // Arrange
//        let url = try XCTUnwrap(URL(string: "https://invalid-url"))
//
//        let config = URLSessionConfiguration.ephemeral
//        config.protocolClasses = [URLProtocolFileStorageClientFailedMock.self]
//
//        let authStateMock = AuthStateProtocolMock(
//            accessToken: "testAccessToken",
//            clientAppID: "testClientAppID",
//            deviceID: "testDeviceID",
//            wsUniqueID: "testWsUniqueID"
//        )
//        let sutFileClient = FileStorageClient(
//            baseURL: url,
//            authState: authStateMock,
//            urlSessionConfiguration: config
//        )
//
//        let data = try XCTUnwrap("Test Data".data(using: .utf8))
//        let mimeType = APIClientMimeType.plain
//        let filename = "test.txt"
//        let expectedError = NSError(domain: NSURLErrorDomain, code: -1003, userInfo: nil)
//        let expectation = XCTestExpectation(description: "Upload fails with invalid URL")
//
//        // Act
//        let task = try sutFileClient.uploadSync(
//            data: data,
//            filename: filename,
//            mimeType: mimeType
//        ) { result in
//
//            // Assert
//            switch result {
//            case let .success(url):
//                XCTAssertNotNil(url)
//                XCTFail("Upload should not complete")
//            case let .failure(error):
//                XCTAssertEqual(error, APIClient.NetworkError.urlSession(expectedError))
//            }
//            expectation.fulfill()
//        }
//
//        XCTAssertNotNil(task)
//        wait(for: [expectation], timeout: 5.0)
//    }

    func testDownloadInvalidFileInfo() throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolFileStorageClientFailedMock.self]

        let authStateMock = AuthStateProtocolMock(
            accessToken: "testAccessToken",
            clientAppID: "testClientAppID",
            deviceID: "testDeviceID",
            wsUniqueID: "testWsUniqueID"
        )
        let sutFileClient = FileStorageClient(
            baseURL: url,
            authState: authStateMock,
            urlSessionConfiguration: config
        )

        let fileInfo = FileInfo(uuid: "", privacy: .public) // Invalid UUID
        let expectation = XCTestExpectation(description: "Download fails with invalid file info")

        // Act
        let task = try sutFileClient.download(file: fileInfo) { result in

            // Assert
            switch result {
            case let .success(url):
                XCTAssertNotNil(url)
                XCTFail("Upload should not complete")
            case let .failure(error):
                XCTAssertEqual(error, APIClient.NetworkError.unknown)
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        wait(for: [expectation], timeout: 5.0)
    }
    
    // FIXME: - Need to correct
//    func testDownloadInvalidURL() throws {
//        // Arrange
//        let url = try XCTUnwrap(URL(string: "https://invalid-url"))
//
//        let config = URLSessionConfiguration.ephemeral
//        config.protocolClasses = [URLProtocolFileStorageClientFailedMock.self]
//
//        let authStateMock = AuthStateProtocolMock(
//            accessToken: "testAccessToken",
//            clientAppID: "testClientAppID",
//            deviceID: "testDeviceID",
//            wsUniqueID: "testWsUniqueID"
//        )
//        let sutFileClient = FileStorageClient(
//            baseURL: url,
//            authState: authStateMock,
//            urlSessionConfiguration: config
//        )
//
//        let fileInfo = FileInfo(uuid: "test-uuid", privacy: .public)
//        let expectedError = NSError(domain: NSURLErrorDomain, code: -1003, userInfo: nil)
//        let expectation = XCTestExpectation(description: "Download fails with invalid URL")
//
//        // Act
//        let task = try sutFileClient.download(file: fileInfo) { result in
//
//            // Assert
//            switch result {
//            case let .success(url):
//                XCTAssertNotNil(url)
//                XCTFail("Upload should not complete")
//            case let .failure(error):
//                XCTAssertEqual(error, APIClient.NetworkError.urlSession(expectedError))
//            }
//            expectation.fulfill()
//        }
//
//        XCTAssertNotNil(task)
//        wait(for: [expectation], timeout: 5.0)
//    }
}
