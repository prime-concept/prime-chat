//
//  MessageClientTests.swift
//  empty_projectTests
//
//  Created by Hayk Kolozyan on 17.05.24.
//

import XCTest
@testable import ChatSDK

final class MessagesClientTests: XCTestCase {

    let authState = AuthState(
        accessToken: "accessToken",
        clientAppID: "clientAppID",
        deviceID: "deviceID",
        wsUniqueID: "wsUniqueID"
    )

    // MARK: - CreateMessage

    func testCreateMessage() throws {
        // Arrange
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMessagesClientSuccessMock.self]

        let messagesClient = MessagesClient(
            baseURL: url,
            authState: authState,
            urlSessionConfiguration: config
        )

        let message = Message(
            guid: "1",
            channelID: "11",
            hostingChannelIDs: [],
            timestamp: 1 ,
            status: .new
        )
        let time = 1627477381
        let expectation = expectation(description: "Create Message")

        // Act
        let task = try messagesClient.create(message: message, time: time) { result in
            // Assert
            switch result {
            case .success(let response):
                XCTAssertEqual(response.httpStatusCode, 200)
            case .failure:
                XCTFail("Expected success response")
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        waitForExpectations(timeout: 5, handler: nil)
    }

    // MARK: - RetrieveMessages

    func testRetrieveMessagesOlder() throws {

        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMessagesClientSuccessMock.self]

        let messagesClient = MessagesClient(
            baseURL: url,
            authState: authState,
            urlSessionConfiguration: config
        )

        let channelID = "general"
        let time = 1627477381
        let direction: MessagesLoadDirection = .older
        let expectation = expectation(description: "Retrieve Messages")

        let task = try messagesClient.retrieve(
            channelID: channelID,
            guid: nil,
            limit: nil,
            time: time,
            fromTime: nil,
            toTime: nil,
            direction: direction
        ) { result in
            switch result {
            case .success(let response):
                guard
                    let data = response.data,
                    let first = data.items.first,
                    let last = data.items.last
                else {
                    XCTFail("data must exist")
                    return
                }
                XCTAssertEqual(data.items.count, 2)
                XCTAssertTrue(first.timestamp < last.timestamp)
            case .failure:
                XCTFail("Expected success response")
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRetrieveMessagesNewer() throws {
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMessagesClientSuccessMock.self]

        let messagesClient = MessagesClient(
            baseURL: url,
            authState: authState,
            urlSessionConfiguration: config
        )

        let channelID = "general"
        let time = 1627477381
        let direction: MessagesLoadDirection = .newer
        let expectation = expectation(description: "Retrieve Messages")

        let task = try messagesClient.retrieve(
            channelID: channelID,
            guid: nil,
            limit: nil,
            time: time,
            fromTime: nil,
            toTime: nil,
            direction: direction
        ) { result in
            switch result {
            case .success(let response):
                guard
                    let data = response.data,
                    let first = data.items.first,
                    let last = data.items.last
                else {
                    XCTFail("data must exist")
                    return
                }

                XCTAssertEqual(data.items.count, 2)
                XCTAssertTrue(first.timestamp > last.timestamp)
            case .failure:
                XCTFail("Expected success response")
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRetrieveMessagesFail() throws {
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMessagesClientFailedMock.self]

        let messagesClient = MessagesClient(
            baseURL: url,
            authState: authState,
            urlSessionConfiguration: config
        )

        let channelID = "general"
        let time = 1627477381
        let direction: MessagesLoadDirection = .older
        let expectation = expectation(description: "Retrieve Messages")

        let task = try messagesClient.retrieve(
            channelID: channelID,
            guid: nil,
            limit: nil,
            time: time,
            fromTime: nil,
            toTime: nil,
            direction: direction
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failed response")
            case let .failure(error):
                XCTAssertNotNil(error, "Expected an error but got nil")
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        waitForExpectations(timeout: 5, handler: nil)
    }

    // MARK: - MessageStatus

    func testUpdateMessageStatusSuccess() throws {
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMessagesClientSuccessMock.self]

        let messagesClient = MessagesClient(
            baseURL: url,
            authState: authState,
            urlSessionConfiguration: config
        )

        let guids = ["msg1", "msg2"]
        let status: MessageStatus = .seen
        let expectation = expectation(description: "Update Message Status")

        let task = try messagesClient.update(guids: guids, status: status) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.httpStatusCode, 200)
            case .failure:
                XCTFail("Expected success response")
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testUpdateMessageStatusFail() throws {
        let url = try XCTUnwrap(URL(string: "example.com"))

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMessagesClientFailedMock.self]

        let messagesClient = MessagesClient(
            baseURL: url,
            authState: authState,
            urlSessionConfiguration: config
        )

        let guids = ["msg1", "msg2"]
        let status: MessageStatus = .seen
        let expectation = expectation(description: "Update Message Status")
        
        let task = try messagesClient.update(guids: guids, status: status) { result in
            switch result {
            case .success:
                XCTFail("Expected failed response")
            case let .failure(error):
                XCTAssertNotNil(error, "Expected an error but got nil")
            }
            expectation.fulfill()
        }

        XCTAssertNotNil(task)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
