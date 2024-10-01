//
//  ResponseCacheServiceTests.swift
//  
//
//  Created by Hayk Kolozyan on 10.06.24.
//

import XCTest
@testable import ChatSDK

class ResponseCacheServiceTests: XCTestCase {

    var cacheService: ResponseCacheService!

    override func setUpWithError() throws {
        super.setUp()
        cacheService = ResponseCacheService.shared
    }

    override func tearDownWithError() throws {
        // Clear cache after each test to ensure no data persists between tests
        cacheService = nil
        super.tearDown()
    }

    // MARK: - shared instance

    func testSharedInstance() {
        let instance1 = ResponseCacheService.shared
        let instance2 = ResponseCacheService.shared

        XCTAssert(instance1 === instance2, "ResponseCacheService.shared should return the same instance")
    }

    // MARK: - write

    func testWriteDataToCache() throws {
        // Arrange
        let cacheDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let enumerator = FileManager.default.enumerator(atPath: cacheDirectory.path)
        var isFileExist = false

        // Act
        cacheService.write(
            data: Constants.testData,
            for: Constants.testURL,
            parameters: Constants.testParameters
        )

        while let element = enumerator?.nextObject() as? String {
            if (element as NSString).lastPathComponent == "Data.dat" {
                isFileExist = true
            }
        }

        // Assert
        XCTAssertTrue(isFileExist)
    }

    // MARK: - read

    func testReadDataFromCache() throws {
        // Arrange
        cacheService.write(
            data: Constants.testData,
            for: Constants.testURL,
            parameters: Constants.testParameters
        )

        // Act
        let retrievedData = cacheService.data(for: Constants.testURL, parameters: Constants.testParameters)

        // Assert
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData, Constants.testData)
    }

    func testNotificationOnCacheClear() {
        // Arrange
        let expectation = expectation(description: "Data should be nil after logging out notification")
        expectation.expectedFulfillmentCount = 2
        cacheService.write(
            data: Constants.testData,
            for: Constants.testURL,
            parameters: Constants.testParameters
        )
        var notificationReceived: Notification?
        var notificationErrorReceived: NSError?
        var retrievedData: Data?

        // Act
        NotificationCenter.default.post(name: .shouldClearCache, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            retrievedData = cacheService.data(
                for: Constants.testURL,
                parameters: Constants.testParameters
            )
            expectation.fulfill()
        }

        let observer = NotificationCenter.default.addObserver(
            forName: .chatSDKDidEncounterError,
            object: nil,
            queue: .main)
        { notification in
            notificationReceived = notification
            notificationErrorReceived = notification.userInfo?["error"] as? NSError
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 5.0)

        XCTAssertNil(retrievedData, "Retrieved data should be nil after the notification")
        XCTAssertNotNil(notificationReceived, "Expected not to receive a notification")
        XCTAssertEqual(
            notificationReceived?.name,
            .chatSDKDidEncounterError,
            "Notification name should be chatSDKDidEncounterError"
        )

        XCTAssertEqual(notificationErrorReceived?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(notificationErrorReceived?.code, 260)

        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - notifications

    func testNotificationOnLogout() {
        // Arrange
        let expectation = expectation(description: "Data should be nil after logging out notification")
        expectation.expectedFulfillmentCount = 2
        cacheService.write(
            data: Constants.testData,
            for: Constants.testURL,
            parameters: Constants.testParameters
        )
        var notificationReceived: Notification?
        var notificationErrorReceived: NSError?
        var retrievedData: Data?

        // Act
        NotificationCenter.default.post(name: .loggedOut, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            retrievedData = cacheService.data(
                for: Constants.testURL,
                parameters: Constants.testParameters
            )
            expectation.fulfill()
        }

        let observer = NotificationCenter.default.addObserver(
            forName: .chatSDKDidEncounterError,
            object: nil,
            queue: .main) { notification in
                notificationReceived = notification
                notificationErrorReceived = notification.userInfo?["error"] as? NSError
                expectation.fulfill()
            }

        // Assert
        wait(for: [expectation], timeout: 5.0)

        XCTAssertNil(retrievedData, "Retrieved data should be nil after the notification")
        XCTAssertNotNil(notificationReceived, "Expected not to receive a notification")
        XCTAssertEqual(
            notificationReceived?.name,
            .chatSDKDidEncounterError,
            "Notification name should be chatSDKDidEncounterError"
        )

        XCTAssertEqual(notificationErrorReceived?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(notificationErrorReceived?.code, 260)

        NotificationCenter.default.removeObserver(observer)
    }

    func testIncorrectNotification() {
        // Arrange
        cacheService.write(
            data: Constants.testData,
            for: Constants.testURL,
            parameters: Constants.testParameters
        )

        // Act
        NotificationCenter.default.post(
            name: Notification.Name("notSuitableNotification"),
            object: nil
        )

        // Assert
        let retrievedData = cacheService.data(for: Constants.testURL, parameters: Constants.testParameters)
        XCTAssertNotNil(retrievedData, "Retrieved data should not be nil after the incorrect notification")
        XCTAssertEqual(
            retrievedData,
            Constants
                .testData
                .aesEncrypt(key: Constants.encryptionKey)?
                .aesDecrypt(key: Constants.encryptionKey),
            "Retrieved data should match the original data after the incorrect notification"
        )
    }
}

extension ResponseCacheServiceTests {
    enum Constants {
        static let testURL = URL(string: "tests")!
        static let testData = "Test data".data(using: .utf8)!
        static let testParameters: [String: Any] = ["param1": "value1"]
        static let encryptionKey = "e3b0c44298fc1c149afbf4c8996fb92"
    }
}
