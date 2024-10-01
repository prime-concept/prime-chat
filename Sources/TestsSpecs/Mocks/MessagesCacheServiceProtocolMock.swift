import Foundation

class MessagesCacheServiceProtocolMock: MessagesCacheServiceProtocol {

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

    var invokedRetrieve = false
    var invokedRetrieveCount = 0
    var invokedRetrieveParameters: (channelID: String, limit: Int, from: Int)?
    var invokedRetrieveParametersList = [(channelID: String, limit: Int, from: Int)]()
    var stubbedRetrieveResult: [Message]! = []

    func retrieve(channelID: String, limit: Int, from: Int) -> [Message] {
        invokedRetrieve = true
        invokedRetrieveCount += 1
        invokedRetrieveParameters = (channelID, limit, from)
        invokedRetrieveParametersList.append((channelID, limit, from))
        return stubbedRetrieveResult
    }

    var invokedRetrieveChannelID = false
    var invokedRetrieveChannelIDCount = 0
    var invokedRetrieveChannelIDParameters: (channelID: String, limit: Int, offsetGUID: String?, requestOlderMessages: Bool)?
    var invokedRetrieveChannelIDParametersList = [(channelID: String, limit: Int, offsetGUID: String?, requestOlderMessages: Bool)]()
    var stubbedRetrieveChannelIDResult: [Message]! = []

    func retrieve(channelID: String, limit: Int, offsetGUID: String?, requestOlderMessages: Bool) -> [Message] {
        invokedRetrieveChannelID = true
        invokedRetrieveChannelIDCount += 1
        invokedRetrieveChannelIDParameters = (channelID, limit, offsetGUID, requestOlderMessages)
        invokedRetrieveChannelIDParametersList.append((channelID, limit, offsetGUID, requestOlderMessages))
        return stubbedRetrieveChannelIDResult
    }

    var invokedSave = false
    var invokedSaveCount = 0
    var invokedSaveParameters: (messages: [Message], Void)?
    var invokedSaveParametersList = [(messages: [Message], Void)]()

    func save(messages: [Message]) {
        invokedSave = true
        invokedSaveCount += 1
        invokedSaveParameters = (messages, ())
        invokedSaveParametersList.append((messages, ()))
    }

    var invokedDelete = false
    var invokedDeleteCount = 0
    var invokedDeleteParameters: (messages: [Message], Void)?
    var invokedDeleteParametersList = [(messages: [Message], Void)]()

    func delete(messages: [Message]) {
        invokedDelete = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (messages, ())
        invokedDeleteParametersList.append((messages, ()))
    }
}
