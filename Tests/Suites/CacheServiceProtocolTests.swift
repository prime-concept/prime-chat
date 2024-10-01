//
//  CacheServiceProtocolTests.swift
//
//
//  Created by Hayk Kolozyan on 04.06.24.
//

import XCTest
@testable import ChatSDK

final class CacheServiceProtocolTests: XCTestCase {

    var sutCacheService: CacheServiceProtocol!

    var filesCacheServiceMock: FilesCacheServiceProtocolMock!
    var databaseWriterMock: DatabaseWriterMock!

    override func setUp() {
        super.setUp()

        filesCacheServiceMock = FilesCacheServiceProtocolMock()
        databaseWriterMock = DatabaseWriterMock()
        databaseWriterMock.stubbedBarrierWriteWithoutTransactionResult = ()
        
        sutCacheService = CacheService(
            filesCacheService: filesCacheServiceMock, 
            pool: databaseWriterMock
        )
    }

    override func tearDown() {
        sutCacheService = nil
        filesCacheServiceMock = nil
        databaseWriterMock = nil
        super.tearDown()
    }

    // MARK: - notifications

    func testShouldClearCacheNotification() {
        // Arrange
        let expectation = expectation(description: "Notification")

        // Act
        NotificationCenter.default.post(name: .shouldClearCache, object: nil)

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(databaseWriterMock.invokedWriteWithoutTransaction)
        XCTAssertTrue(filesCacheServiceMock.invokedErase)
    }

    func testLoggedOutNotification() {
        // Arrange
        let expectation = expectation(description: "Notification")

        // Act
        NotificationCenter.default.post(name: .loggedOut, object: nil)
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(filesCacheServiceMock.invokedErase)
    }

    func testNotExistedNotification() {
        // Arrange
        let expectation = expectation(description: "Notification")
        let notExistedNotificationName = Notification.Name("notExistedNotificationName")

        // Act
        NotificationCenter.default.post(name: notExistedNotificationName, object: nil)

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 5.0)
        XCTAssertFalse(filesCacheServiceMock.invokedErase)
    }

    // MARK: - retrieve messages by channelID with limit

    func testRetrieveChannelIDLimitFromMessages() {
        // Arrange
        databaseWriterMock.stubbedReadResult = [Constants.message1, Constants.message2]

        // Act
        let retrievedMessages = sutCacheService.retrieve(channelID: "111", limit: 2, from: 0)

        // Assert
        XCTAssertFalse(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages, [Constants.message1, Constants.message2])
    }

    func testRetrieveWrongChannelIDLimitFromMessages() {
        // Arrange
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedMessages = sutCacheService.retrieve(channelID: "!@#", limit: 2, from: 0)

        // Assert
        XCTAssertTrue(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages, [])
    }

    func testRetrieveChannelIDWrongLimitFromMessages() {
        // Arrange
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedMessages = sutCacheService.retrieve(channelID: "111", limit: -1, from: 0)

        // Assert
        XCTAssertTrue(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages, [])
    }

    // MARK: - retrieve messages by guids

    func testRetrieveMessagesWithValidGuids() {
        // Arrange
        databaseWriterMock.stubbedReadResult = [Constants.message1, Constants.message2]

        // Act
        let retrievedMessages = sutCacheService.retrieveMessages(guids: ["1"])

        // Assert
        XCTAssertFalse(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages.first, Constants.message1)
    }

    func testRetrieveMessagesWithInvalidGuids() {
        // Arrange
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedMessages = sutCacheService.retrieveMessages(guids: ["123-abc-45';DROP TABLE MESSAGES;"])

        // Assert
        XCTAssertTrue(retrievedMessages.isEmpty)
    }

    // MARK: - retrieve last messages

    func testRetrieveLastMessages() {
        // Arrange
        databaseWriterMock.stubbedReadResult = [Constants.message2, Constants.message3]

        // Act
        let retrievedMessages = sutCacheService.retrieveLastMessages()

        // Assert
        XCTAssertFalse(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages.count, 2)
        XCTAssertEqual(retrievedMessages.first?.guid, Constants.message2.guid)
        XCTAssertEqual(retrievedMessages.last?.guid, Constants.message3.guid)
    }

    // MARK: - retrieve messages by channelID with limit offsetGUID and requestOlderMessages

    func testRetrieveMessagesByChannelIDLimitOffsetGUID() {
        databaseWriterMock.stubbedReadResult = [Constants.message1, Constants.message2]

        // Act
        let retrievedMessages = sutCacheService.retrieve(
            channelID: Constants.channelID,
            limit: 10,
            offsetGUID: Constants.message1.guid,
            requestOlderMessages: true
        )

        // Assert
        XCTAssertFalse(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages, [Constants.message1, Constants.message2])
        XCTAssertFalse(databaseWriterMock.invokedAsyncRead)
    }

    func testRetrieveMessagesByWrongChannelIDLimitOffsetGUID() {
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedMessages = sutCacheService.retrieve(
            channelID: "!@#",
            limit: 10,
            offsetGUID: Constants.message1.guid,
            requestOlderMessages: true
        )

        // Assert
        XCTAssertTrue(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages, [])
        XCTAssertFalse(databaseWriterMock.invokedAsyncRead)
    }

    func testRetrieveMessagesByChannelIDWrongLimitOffsetGUID() {
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedMessages = sutCacheService.retrieve(
            channelID: Constants.channelID,
            limit: -1,
            offsetGUID: Constants.message1.guid,
            requestOlderMessages: true
        )

        // Assert
        XCTAssertTrue(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages, [])
        XCTAssertFalse(databaseWriterMock.invokedAsyncRead)
    }

    func testRetrieveMessagesByChannelIDLimitWrongOffsetGUID() {
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedMessages = sutCacheService.retrieve(
            channelID: Constants.channelID,
            limit: 10,
            offsetGUID: "!@#",
            requestOlderMessages: true
        )

        // Assert
        XCTAssertTrue(retrievedMessages.isEmpty)
        XCTAssertEqual(retrievedMessages, [])
        XCTAssertFalse(databaseWriterMock.invokedAsyncRead)
    }

    // MARK: - save

    func testSaveMessagesSuccess() {
        // Arrange

        databaseWriterMock.stubbedWriteWithoutTransactionResult = ()

        // Act
        sutCacheService.save(messages: [Constants.message1])

        // Assert

        XCTAssertEqual(databaseWriterMock.invokedWriteWithoutTransactionCount, 1)
    }

    // MARK: - delete

    func testDeleteMessages() {
        // Arrange

        databaseWriterMock.stubbedWriteWithoutTransactionResult = ()

        // Act
        sutCacheService.delete(messages: [Constants.message1])

        // Assert

        XCTAssertEqual(databaseWriterMock.invokedWriteWithoutTransactionCount, 1)
    }

    // MARK: - drafts

    func testRetrieveDraftsByChannelID() {
        // Arrange
        let expectedDrafts: [MessageDraft] = [Constants.draftFilled, Constants.draftEmpty]
        databaseWriterMock.stubbedReadResult = [Constants.draftFilled, Constants.draftEmpty]

        // Act
        let retrievedDrafts = sutCacheService.retrieveDrafts(channelID: Constants.channelID)

        // Assert
        XCTAssertEqual(retrievedDrafts, expectedDrafts)
    }

    func testRetrieveDraftsByWrongChannelID() {
        // Arrange
        let expectedDrafts: [MessageDraft] = [Constants.draftFilled, Constants.draftEmpty]
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedDrafts = sutCacheService.retrieveDrafts(channelID: "!@#$%^&*()")

        // Assert
        XCTAssertTrue(retrievedDrafts.isEmpty)
    }

    func testRetrieveDraftByChannelIDAndMessageGUID() {
        // Arrange
        databaseWriterMock.stubbedReadResult = [Constants.draftFilled, Constants.draftEmpty]

        // Act
        let retrievedDraft = sutCacheService.retrieveDraft(
            channelID: Constants.channelID,
            messageGUID: Constants.draftFilled.messageGUID
        )

        // Assert
        XCTAssertEqual(retrievedDraft, Constants.draftFilled)
        XCTAssertTrue(databaseWriterMock.invokedRead)
    }

    func testRetrieveDraftByWrongChannelIDAndMessageGUID() {
        // Arrange
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedDraft = sutCacheService.retrieveDraft(
            channelID: Constants.channelID,
            messageGUID: Constants.draftFilled.messageGUID
        )

        // Assert
        XCTAssertNil(retrievedDraft)
        XCTAssertTrue(databaseWriterMock.invokedRead)
    }

    func testRetrieveDraftByChannelIDAndWrongMessageGUID() {
        // Arrange
        databaseWriterMock.stubbedReadResult = []

        // Act
        let retrievedDraft = sutCacheService.retrieveDraft(
            channelID: Constants.channelID,
            messageGUID: Constants.draftFilled.messageGUID
        )

        // Assert
        XCTAssertNil(retrievedDraft)
        XCTAssertTrue(databaseWriterMock.invokedRead)
    }

    func testSaveDraft() {
        // Arrange
        databaseWriterMock.stubbedWriteWithoutTransactionResult = ()

        // Act
        sutCacheService.save(draft: Constants.draftFilled)

        // Assert
        XCTAssertTrue(databaseWriterMock.invokedWriteWithoutTransaction)
    }

    func testDeleteDraft() {
        // Arrange
        databaseWriterMock.stubbedWriteWithoutTransactionResult = true

        // Act
        sutCacheService.delete(draft: Constants.draftFilled)

        // Assert
        XCTAssertTrue(databaseWriterMock.invokedWriteWithoutTransaction)
    }

    // MARK: - FilesCacheServiceProtocol

    func testExistsWithCacheKey() {
        // Arrange
        let cacheKey = "testCacheKey"
        filesCacheServiceMock.stubbedExistsCacheKeyResult = URL(string: "example.ru")

        // Act
        let resultURL = sutCacheService.exists(cacheKey: cacheKey)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedExistsCacheKey)
        XCTAssertEqual(filesCacheServiceMock.invokedExistsCacheKeyParameters?.cacheKey, cacheKey)
        XCTAssertEqual(resultURL, URL(string: "example.ru"))
    }

    func testExistsWithCacheKeyNotExisted() {
        // Arrange
        let cacheKey = "12345234565"
        filesCacheServiceMock.stubbedExistsCacheKeyResult = nil

        // Act
        let resultURL = sutCacheService.exists(cacheKey: cacheKey)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedExistsCacheKey)
        XCTAssertEqual(filesCacheServiceMock.invokedExistsCacheKeyParameters?.cacheKey, cacheKey)
        XCTAssertNil(resultURL)
    }

    func testExistsWithFile() {
        // Arrange
        let fileInfo = FileInfo(uuid: "testFile")
        filesCacheServiceMock.stubbedExistsFileResult = URL(string: "example.ru")

        // Act
        let resultURL = sutCacheService.exists(file: fileInfo)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedExistsFile)
        XCTAssertEqual(filesCacheServiceMock.invokedExistsFileParameters?.file.uuid, fileInfo.uuid)
        XCTAssertEqual(resultURL, URL(string: "example.ru"))
    }    

    func testExistsWithFileNotExisted() {
        // Arrange
        let fileInfo = FileInfo(uuid: "testFile")
        filesCacheServiceMock.stubbedExistsFileResult = nil

        // Act
        let resultURL = sutCacheService.exists(file: fileInfo)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedExistsFile)
        XCTAssertEqual(filesCacheServiceMock.invokedExistsFileParameters?.file.uuid, fileInfo.uuid)
        XCTAssertNil(resultURL)
    }

    func testRetrieveWithFile() {
        // Arrange
        let fileInfo = FileInfo(uuid: "testFile")
        filesCacheServiceMock.stubbedRetrieveFileResult = Data()

        // Act
        let resultData = sutCacheService.retrieve(file: fileInfo)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedRetrieveFile)
        XCTAssertEqual(filesCacheServiceMock.invokedRetrieveFileParameters?.file.uuid, fileInfo.uuid)
        XCTAssertEqual(resultData, Data())
    }

    func testRetrieveWithFileNotExisted() {
        // Arrange
        let fileInfo = FileInfo(uuid: "testFile")
        filesCacheServiceMock.stubbedRetrieveFileResult = nil

        // Act
        let resultData = sutCacheService.retrieve(file: fileInfo)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedRetrieveFile)
        XCTAssertEqual(filesCacheServiceMock.invokedRetrieveFileParameters?.file.uuid, fileInfo.uuid)
        XCTAssertNil(resultData)
    }
    
    func testRetrieveWithWrongFileName() {
        // Arrange
        let fileInfo = FileInfo(uuid: "!@#")
        filesCacheServiceMock.stubbedRetrieveFileResult = nil

        // Act
        let resultData = sutCacheService.retrieve(file: fileInfo)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedRetrieveFile)
        XCTAssertEqual(filesCacheServiceMock.invokedRetrieveFileParameters?.file.uuid, fileInfo.uuid)
        XCTAssertNil(resultData)
    }

    func testSaveWithFile() {
        // Arrange
        let fileInfo = FileInfo(uuid: "testFile")
        let data = Data()

        // Act
        sutCacheService.save(file: fileInfo, data: data)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedSaveFile)
        XCTAssertEqual(filesCacheServiceMock.invokedSaveFileParameters?.file.uuid, fileInfo.uuid)
        XCTAssertEqual(filesCacheServiceMock.invokedSaveFileParameters?.data, data)
    }

    func testRetrieveWithCacheKey() {
        // Arrange
        let cacheKey = "testCacheKey"
        filesCacheServiceMock.stubbedRetrieveCacheKeyResult = Data()

        // Act
        let resultData = sutCacheService.retrieve(cacheKey: cacheKey)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedRetrieveCacheKey)
        XCTAssertEqual(filesCacheServiceMock.invokedRetrieveCacheKeyParameters?.cacheKey, cacheKey)
        XCTAssertEqual(resultData, Data())
    }

    func testRetrieveWithCacheKeyNotExisted() {
        // Arrange
        let cacheKey = "testCacheKey"
        filesCacheServiceMock.stubbedRetrieveCacheKeyResult = nil

        // Act
        let resultData = sutCacheService.retrieve(cacheKey: cacheKey)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedRetrieveCacheKey)
        XCTAssertEqual(filesCacheServiceMock.invokedRetrieveCacheKeyParameters?.cacheKey, cacheKey)
        XCTAssertNil(resultData)
    }

    func testRetrieveWithWrongCacheKey() {
        // Arrange
        let cacheKey = "!@#"
        filesCacheServiceMock.stubbedRetrieveCacheKeyResult = nil

        // Act
        let resultData = sutCacheService.retrieve(cacheKey: cacheKey)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedRetrieveCacheKey)
        XCTAssertEqual(filesCacheServiceMock.invokedRetrieveCacheKeyParameters?.cacheKey, cacheKey)
        XCTAssertNil(resultData)
    }

    func testSaveWithCacheKey() {
        // Arrange
        let cacheKey = "testCacheKey"
        let data = Data()

        // Act
        sutCacheService.save(cacheKey: cacheKey, data: data)

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedSaveCacheKey)
        XCTAssertEqual(filesCacheServiceMock.invokedSaveCacheKeyParameters?.cacheKey, cacheKey)
        XCTAssertEqual(filesCacheServiceMock.invokedSaveCacheKeyParameters?.data, data)
    }

    func testErase() {
        // Act
        sutCacheService.erase()

        // Assert
        XCTAssertTrue(filesCacheServiceMock.invokedErase)
    }
}

// MARK: - constants

extension CacheServiceProtocolTests {
    enum Constants {
        static let channelID = "111"
        static let message1 = Message(
            guid: "1",
            clientID: "11",
            channelID: channelID,
            hostingChannelIDs: [],
            timestamp: 1 ,
            relativeOrder: 1,
            source: .chat,
            senderName: "11",
            status: .new,
            ttl: 1,
            updatedAt: 1,
            content: TextContent(string: "123"),
            contentMeta: ContentMeta(),
            replyToID: "11",
            replyTo: []
        )
        static let message2 = Message(
            guid: "2",
            clientID: "22",
            channelID: channelID,
            hostingChannelIDs: [],
            timestamp: 2 ,
            relativeOrder: 2,
            source: .chat,
            senderName: "22",
            status: .new,
            ttl: 2,
            updatedAt: 2,
            content: TextContent(string: "456"),
            contentMeta: ContentMeta(),
            replyToID: "11",
            replyTo: []
        )
        static let message3 = Message(
            guid: "3",
            clientID: "22",
            channelID: channelID,
            hostingChannelIDs: [],
            timestamp: 3 ,
            relativeOrder: 3,
            source: .chat,
            senderName: "3",
            status: .new,
            ttl: 3,
            updatedAt: 3,
            content: TextContent(string: "789"),
            contentMeta: ContentMeta(),
            replyToID: "11",
            replyTo: []
        )

        static let draftEmpty = MessageDraft.emptyDraft(channelID: channelID)
        static let draftFilled = MessageDraft(
            messageGUID: "333",
            messageStatus: .new,
            channelID: channelID,
            text: "text",
            updatedAt: Date(),
            attachments: DraftAttachmentsContainer(
                values: [DraftAttachment(
                    type: "qqq",
                    properties: "{ text: \"text\" }"
                )]
            )
        )
    }
}
