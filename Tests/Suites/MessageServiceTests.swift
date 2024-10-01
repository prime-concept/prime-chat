import XCTest
@testable import ChatSDK

class MessageServiceTests: XCTestCase {

    var sutMessageService: MessageService!

    var messagesClientMock: MessagesClientProtocolMock!
    var webSocketClientMock: WebSocketClientProtocolMock!
    var messagesCacheServiceMock: MessagesCacheServiceProtocolMock!


    override func setUp() {
        super.setUp()

        messagesClientMock = MessagesClientProtocolMock()
        webSocketClientMock = WebSocketClientProtocolMock()
        messagesCacheServiceMock = MessagesCacheServiceProtocolMock()

        sutMessageService = MessageService(
            messagesClient: messagesClientMock,
            webSocketClient: webSocketClientMock,
            messagesCacheService: messagesCacheServiceMock
        )
    }

    override func tearDown() {
        sutMessageService = nil
        messagesClientMock = nil
        webSocketClientMock = nil
        messagesCacheServiceMock = nil
        super.tearDown()
    }

    // MARK: - factory method

    func testMakeMessagesProvider() {
        // Arrange
        let channelID = "testChannel"
        let messageTypesToIgnore: [MessageType] = []
        webSocketClientMock.isConnected = false

        // Act
        let provider = sutMessageService.makeMessagesProvider(
            channelID: channelID,
            messageTypesToIgnore: messageTypesToIgnore
        )

        // Assert
        XCTAssertNotNil(provider)
        XCTAssertEqual(webSocketClientMock.connectVoidCallsCount, 1)
    }

    // MARK: - sends

    func testSendSuccess() {
        // Arrange
        let expectation = self.expectation(description: "send completes")

        var testMessage: Message?
        messagesClientMock.createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskClosure = { message, _, completion in

            testMessage = message
            completion(.success(APIClient.HTTPResult<CreateMessageResponse>.init(httpStatusCode: 200, data: nil)))
            return nil
        }

        // Act
        sutMessageService.send(
            guid: "testGuid",
            channelID: "testChannel",
            content: MessageContentMock(string: "testContent"),
            contentMeta: nil,
            replyTo: nil
        ) { result in

            // Assert
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("Expected success but got failure")
            }
            expectation.fulfill()
        }

        XCTAssertEqual(testMessage?.guid, "testGuid")
        XCTAssertEqual(testMessage?.channelID, "testChannel")
        XCTAssertEqual((testMessage?.content as? MessageContentMock)?.invokedString, "testContent")
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testSendFailure() {
        // Arrange
        let expectation = self.expectation(description: "send completes")

        var testMessage: Message?
        let expectedError = NSError(domain: "ChatSDK.APIClient.NetworkError", code: 0, userInfo: nil)

        messagesClientMock.createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskClosure = { message, _, completion in

            testMessage = message
            completion(.failure(APIClient.NetworkError.urlSession(expectedError as Error)))
            return nil
        }

        // Act
        sutMessageService.send(
            guid: "testGuid",
            channelID: "testChannel",
            content: MessageContentMock(string: "testContent"),
            contentMeta: nil,
            replyTo: nil
        ) { result in

            // Assert
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, expectedError.domain)
                XCTAssertEqual(error.code, expectedError.code)
            default:
                XCTFail("Expected NSError type failure but got different type")
            }
            expectation.fulfill()
        }

        XCTAssertEqual(testMessage?.guid, "testGuid")
        XCTAssertEqual(testMessage?.channelID, "testChannel")
        XCTAssertEqual((testMessage?.content as? MessageContentMock)?.invokedString, "testContent")
        waitForExpectations(timeout: 1, handler: nil)
    }

    // MARK: - updates

    func testUpdateSuccess() {
        // Arrange
        let expectation = self.expectation(description: "update completes")

        var testGuids: [String]?
        let expectedStatus = MessageStatus.sent

        messagesClientMock.updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskClosure = { guids, status, completion in

            testGuids = guids
            completion(.success(APIClient.HTTPResult(httpStatusCode: 200, data: nil)))
            return nil
        }

        // Act
        sutMessageService.update(guids: ["testGuid1", "testGuid2"], status: expectedStatus) { result in

            // Assert
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTFail("Expected success but got failure")
            }
            expectation.fulfill()
        }

        XCTAssertEqual(testGuids, ["testGuid1", "testGuid2"])
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testUpdateFailure() {
        // Arrange
        let expectation = self.expectation(description: "update completes")

        var testGuids: [String]?
        let expectedError = NSError(domain: "ChatSDK.APIClient.NetworkError", code: 0, userInfo: nil)
        let expectedStatus = MessageStatus.sent

        messagesClientMock.updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskClosure = { guids, status, completion in

            testGuids = guids
            completion(.failure(APIClient.NetworkError.urlSession(expectedError as Error)))
            return nil
        }

        // Act
        sutMessageService.update(guids: ["testGuid1", "testGuid2"], status: expectedStatus) { result in
            switch result {
            case .success:
                XCTFail("Expected failure but got success")
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, expectedError.domain)
                XCTAssertEqual(error.code, expectedError.code)
            default:
                XCTFail("Expected NSError type failure but got different type")
            }
            expectation.fulfill()
        }

        // Assert
        XCTAssertEqual(testGuids, ["testGuid1", "testGuid2"])
        waitForExpectations(timeout: 1, handler: nil)
    }
}
