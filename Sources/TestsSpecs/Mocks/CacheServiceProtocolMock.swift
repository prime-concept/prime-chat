//
//  CacheServiceProtocolMock.swift
//
//
//  Created by Hayk Kolozyan on 04.06.24.
//

import Foundation

class CacheServiceProtocolMock: CacheServiceProtocol {

    var invokedRetrieveLastMessages = false
    var invokedRetrieveLastMessagesCount = 0
    var stubbedRetrieveLastMessagesResult: [Message]! = []

    func retrieveLastMessages() -> [Message] {
        invokedRetrieveLastMessages = true
        invokedRetrieveLastMessagesCount += 1
        return stubbedRetrieveLastMessagesResult
    }

    var invokedRetrieveMessages = false
    var invokedRetrieveMessagesCount = 0
    var invokedRetrieveMessagesParameters: (guids: [String], Void)?
    var invokedRetrieveMessagesParametersList = [(guids: [String], Void)]()
    var stubbedRetrieveMessagesResult: [Message]! = []

    func retrieveMessages(guids: [String]) -> [Message] {
        invokedRetrieveMessages = true
        invokedRetrieveMessagesCount += 1
        invokedRetrieveMessagesParameters = (guids, ())
        invokedRetrieveMessagesParametersList.append((guids, ()))
        return stubbedRetrieveMessagesResult
    }

    var invokedRetrieveChannelID = false
    var invokedRetrieveChannelIDCount = 0
    var invokedRetrieveChannelIDParameters: (channelID: String, limit: Int, from: Int)?
    var invokedRetrieveChannelIDParametersList = [(channelID: String, limit: Int, from: Int)]()
    var stubbedRetrieveChannelIDResult: [Message]! = []

    func retrieve(channelID: String, limit: Int, from: Int) -> [Message] {
        invokedRetrieveChannelID = true
        invokedRetrieveChannelIDCount += 1
        invokedRetrieveChannelIDParameters = (channelID, limit, from)
        invokedRetrieveChannelIDParametersList.append((channelID, limit, from))
        return stubbedRetrieveChannelIDResult
    }

    var invokedRetrieveChannelIDLimit = false
    var invokedRetrieveChannelIDLimitCount = 0
    var invokedRetrieveChannelIDLimitParameters: (channelID: String, limit: Int, offsetGUID: String?, requestOlderMessages: Bool)?
    var invokedRetrieveChannelIDLimitParametersList = [(channelID: String, limit: Int, offsetGUID: String?, requestOlderMessages: Bool)]()
    var stubbedRetrieveChannelIDLimitResult: [Message]! = []

    func retrieve(channelID: String, limit: Int, offsetGUID: String?, requestOlderMessages: Bool) -> [Message] {
        invokedRetrieveChannelIDLimit = true
        invokedRetrieveChannelIDLimitCount += 1
        invokedRetrieveChannelIDLimitParameters = (channelID, limit, offsetGUID, requestOlderMessages)
        invokedRetrieveChannelIDLimitParametersList.append((channelID, limit, offsetGUID, requestOlderMessages))
        return stubbedRetrieveChannelIDLimitResult
    }

    var invokedSaveMessages = false
    var invokedSaveMessagesCount = 0
    var invokedSaveMessagesParameters: (messages: [Message], Void)?
    var invokedSaveMessagesParametersList = [(messages: [Message], Void)]()

    func save(messages: [Message]) {
        invokedSaveMessages = true
        invokedSaveMessagesCount += 1
        invokedSaveMessagesParameters = (messages, ())
        invokedSaveMessagesParametersList.append((messages, ()))
    }

    var invokedDeleteMessages = false
    var invokedDeleteMessagesCount = 0
    var invokedDeleteMessagesParameters: (messages: [Message], Void)?
    var invokedDeleteMessagesParametersList = [(messages: [Message], Void)]()

    func delete(messages: [Message]) {
        invokedDeleteMessages = true
        invokedDeleteMessagesCount += 1
        invokedDeleteMessagesParameters = (messages, ())
        invokedDeleteMessagesParametersList.append((messages, ()))
    }

    var invokedRetrieveDrafts = false
    var invokedRetrieveDraftsCount = 0
    var invokedRetrieveDraftsParameters: (channelID: String, Void)?
    var invokedRetrieveDraftsParametersList = [(channelID: String, Void)]()
    var stubbedRetrieveDraftsResult: [MessageDraft]! = []

    func retrieveDrafts(channelID: String) -> [MessageDraft] {
        invokedRetrieveDrafts = true
        invokedRetrieveDraftsCount += 1
        invokedRetrieveDraftsParameters = (channelID, ())
        invokedRetrieveDraftsParametersList.append((channelID, ()))
        return stubbedRetrieveDraftsResult
    }

    var invokedRetrieveDraft = false
    var invokedRetrieveDraftCount = 0
    var invokedRetrieveDraftParameters: (channelID: String, messageGUID: String)?
    var invokedRetrieveDraftParametersList = [(channelID: String, messageGUID: String)]()
    var stubbedRetrieveDraftResult: MessageDraft!

    func retrieveDraft(channelID: String, messageGUID: String) -> MessageDraft? {
        invokedRetrieveDraft = true
        invokedRetrieveDraftCount += 1
        invokedRetrieveDraftParameters = (channelID, messageGUID)
        invokedRetrieveDraftParametersList.append((channelID, messageGUID))
        return stubbedRetrieveDraftResult
    }

    var invokedSaveDraft = false
    var invokedSaveDraftCount = 0
    var invokedSaveDraftParameters: (draft: MessageDraft, Void)?
    var invokedSaveDraftParametersList = [(draft: MessageDraft, Void)]()

    func save(draft: MessageDraft) {
        invokedSaveDraft = true
        invokedSaveDraftCount += 1
        invokedSaveDraftParameters = (draft, ())
        invokedSaveDraftParametersList.append((draft, ()))
    }

    var invokedDeleteDraft = false
    var invokedDeleteDraftCount = 0
    var invokedDeleteDraftParameters: (draft: MessageDraft, Void)?
    var invokedDeleteDraftParametersList = [(draft: MessageDraft, Void)]()

    func delete(draft: MessageDraft) {
        invokedDeleteDraft = true
        invokedDeleteDraftCount += 1
        invokedDeleteDraftParameters = (draft, ())
        invokedDeleteDraftParametersList.append((draft, ()))
    }

    var invokedExistsFile = false
    var invokedExistsFileCount = 0
    var invokedExistsFileParameters: (file: FileInfo, Void)?
    var invokedExistsFileParametersList = [(file: FileInfo, Void)]()
    var stubbedExistsFileResult: URL!

    func exists(file: FileInfo) -> URL? {
        invokedExistsFile = true
        invokedExistsFileCount += 1
        invokedExistsFileParameters = (file, ())
        invokedExistsFileParametersList.append((file, ()))
        return stubbedExistsFileResult
    }

    var invokedExistsCacheKey = false
    var invokedExistsCacheKeyCount = 0
    var invokedExistsCacheKeyParameters: (cacheKey: String, Void)?
    var invokedExistsCacheKeyParametersList = [(cacheKey: String, Void)]()
    var stubbedExistsCacheKeyResult: URL!

    func exists(cacheKey: String) -> URL? {
        invokedExistsCacheKey = true
        invokedExistsCacheKeyCount += 1
        invokedExistsCacheKeyParameters = (cacheKey, ())
        invokedExistsCacheKeyParametersList.append((cacheKey, ()))
        return stubbedExistsCacheKeyResult
    }

    var invokedRetrieveFile = false
    var invokedRetrieveFileCount = 0
    var invokedRetrieveFileParameters: (file: FileInfo, Void)?
    var invokedRetrieveFileParametersList = [(file: FileInfo, Void)]()
    var stubbedRetrieveFileResult: Data!

    func retrieve(file: FileInfo) -> Data? {
        invokedRetrieveFile = true
        invokedRetrieveFileCount += 1
        invokedRetrieveFileParameters = (file, ())
        invokedRetrieveFileParametersList.append((file, ()))
        return stubbedRetrieveFileResult
    }

    var invokedRetrieveCacheKey = false
    var invokedRetrieveCacheKeyCount = 0
    var invokedRetrieveCacheKeyParameters: (cacheKey: String, Void)?
    var invokedRetrieveCacheKeyParametersList = [(cacheKey: String, Void)]()
    var stubbedRetrieveCacheKeyResult: Data!

    func retrieve(cacheKey: String) -> Data? {
        invokedRetrieveCacheKey = true
        invokedRetrieveCacheKeyCount += 1
        invokedRetrieveCacheKeyParameters = (cacheKey, ())
        invokedRetrieveCacheKeyParametersList.append((cacheKey, ()))
        return stubbedRetrieveCacheKeyResult
    }

    var invokedSaveCacheKey = false
    var invokedSaveCacheKeyCount = 0
    var invokedSaveCacheKeyParameters: (cacheKey: String, data: Data)?
    var invokedSaveCacheKeyParametersList = [(cacheKey: String, data: Data)]()
    var stubbedSaveCacheKeyResult: URL!

    func save(cacheKey: String, data: Data) -> URL? {
        invokedSaveCacheKey = true
        invokedSaveCacheKeyCount += 1
        invokedSaveCacheKeyParameters = (cacheKey, data)
        invokedSaveCacheKeyParametersList.append((cacheKey, data))
        return stubbedSaveCacheKeyResult
    }

    var invokedSaveFile = false
    var invokedSaveFileCount = 0
    var invokedSaveFileParameters: (file: FileInfo, data: Data)?
    var invokedSaveFileParametersList = [(file: FileInfo, data: Data)]()
    var stubbedSaveFileResult: URL!

    func save(file: FileInfo, data: Data) -> URL? {
        invokedSaveFile = true
        invokedSaveFileCount += 1
        invokedSaveFileParameters = (file, data)
        invokedSaveFileParametersList.append((file, data))
        return stubbedSaveFileResult
    }

    var invokedErase = false
    var invokedEraseCount = 0

    func erase() {
        invokedErase = true
        invokedEraseCount += 1
    }
}
