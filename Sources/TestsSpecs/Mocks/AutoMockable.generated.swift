// Generated using Sourcery 2.2.4 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif























class WebSocketProtocolMock: WebSocketProtocol {


    var isConnected: Bool {
        get { return underlyingIsConnected }
        set(value) { underlyingIsConnected = value }
    }
    var underlyingIsConnected: (Bool)!
    var onConnect: ((() -> Void)?)
    var onDisconnect: (((Error?) -> Void)?)
    var onText: (((String) -> Void)?)
    var onHttpResponseHeaders: ((([String: String]) -> Void)?)


    //MARK: - connect

    var connectVoidCallsCount = 0
    var connectVoidCalled: Bool {
        return connectVoidCallsCount > 0
    }
    var connectVoidClosure: (() -> Void)?

    func connect() {
        connectVoidCallsCount += 1
        connectVoidClosure?()
    }

    //MARK: - disconnect

    var disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidCallsCount = 0
    var disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidCalled: Bool {
        return disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidCallsCount > 0
    }
    var disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidReceivedArguments: (forceTimeout: TimeInterval?, closeCode: UInt16)?
    var disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidReceivedInvocations: [(forceTimeout: TimeInterval?, closeCode: UInt16)] = []
    var disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidClosure: ((TimeInterval?, UInt16) -> Void)?

    func disconnect(forceTimeout: TimeInterval?, closeCode: UInt16) {
        disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidCallsCount += 1
        disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidReceivedArguments = (forceTimeout: forceTimeout, closeCode: closeCode)
        disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidReceivedInvocations.append((forceTimeout: forceTimeout, closeCode: closeCode))
        disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidClosure?(forceTimeout, closeCode)
    }


}
public class AuthStateProtocolMock: AuthStateProtocol {

    public init() {}

    public var accessToken: String?
    public var clientAppID: String?
    public var deviceID: String?
    public var wsUniqueID: String?
    public var bearerToken: String?


    //MARK: - init

    public var initAccessTokenStringClientAppIDStringDeviceIDStringWsUniqueIDStringAuthStateProtocolReceivedArguments: (accessToken: String?, clientAppID: String?, deviceID: String?, wsUniqueID: String?)?
    public var initAccessTokenStringClientAppIDStringDeviceIDStringWsUniqueIDStringAuthStateProtocolReceivedInvocations: [(accessToken: String?, clientAppID: String?, deviceID: String?, wsUniqueID: String?)] = []
    public var initAccessTokenStringClientAppIDStringDeviceIDStringWsUniqueIDStringAuthStateProtocolClosure: ((String?, String?, String?, String?) -> Void)?

    public required init(accessToken: String?, clientAppID: String?, deviceID: String?, wsUniqueID: String?) {
        initAccessTokenStringClientAppIDStringDeviceIDStringWsUniqueIDStringAuthStateProtocolReceivedArguments = (accessToken: accessToken, clientAppID: clientAppID, deviceID: deviceID, wsUniqueID: wsUniqueID)
        initAccessTokenStringClientAppIDStringDeviceIDStringWsUniqueIDStringAuthStateProtocolReceivedInvocations.append((accessToken: accessToken, clientAppID: clientAppID, deviceID: deviceID, wsUniqueID: wsUniqueID))
        initAccessTokenStringClientAppIDStringDeviceIDStringWsUniqueIDStringAuthStateProtocolClosure?(accessToken, clientAppID, deviceID, wsUniqueID)
    }

}

public class ChatBroadcastListenerProtocolMock: ChatBroadcastListenerProtocol {

    public init() {}



    //MARK: - failNonSentMessages

    public var failNonSentMessagesVoidCallsCount = 0
    public var failNonSentMessagesVoidCalled: Bool {
        return failNonSentMessagesVoidCallsCount > 0
    }
    public var failNonSentMessagesVoidClosure: (() -> Void)?

    public func failNonSentMessages() {
        failNonSentMessagesVoidCallsCount += 1
        failNonSentMessagesVoidClosure?()
    }


}
class ChatPresenterProtocolMock: ChatPresenterProtocol {


    var shouldShowSafeAreaView: Bool {
        get { return underlyingShouldShowSafeAreaView }
        set(value) { underlyingShouldShowSafeAreaView = value }
    }
    var underlyingShouldShowSafeAreaView: (Bool)!
    var bottomViewExists: Bool {
        get { return underlyingBottomViewExists }
        set(value) { underlyingBottomViewExists = value }
    }
    var underlyingBottomViewExists: (Bool)!


    //MARK: - retryMessageSending

    var retryMessageSendingMessageMessageVoidCallsCount = 0
    var retryMessageSendingMessageMessageVoidCalled: Bool {
        return retryMessageSendingMessageMessageVoidCallsCount > 0
    }
    var retryMessageSendingMessageMessageVoidReceivedMessage: (Message)?
    var retryMessageSendingMessageMessageVoidReceivedInvocations: [(Message)] = []
    var retryMessageSendingMessageMessageVoidClosure: ((Message) -> Void)?

    func retryMessageSending(message: Message) {
        retryMessageSendingMessageMessageVoidCallsCount += 1
        retryMessageSendingMessageMessageVoidReceivedMessage = message
        retryMessageSendingMessageMessageVoidReceivedInvocations.append(message)
        retryMessageSendingMessageMessageVoidClosure?(message)
    }

    //MARK: - retryMessageSending

    var retryMessageSendingGuidStringVoidCallsCount = 0
    var retryMessageSendingGuidStringVoidCalled: Bool {
        return retryMessageSendingGuidStringVoidCallsCount > 0
    }
    var retryMessageSendingGuidStringVoidReceivedGuid: (String)?
    var retryMessageSendingGuidStringVoidReceivedInvocations: [(String)] = []
    var retryMessageSendingGuidStringVoidClosure: ((String) -> Void)?

    func retryMessageSending(guid: String) {
        retryMessageSendingGuidStringVoidCallsCount += 1
        retryMessageSendingGuidStringVoidReceivedGuid = guid
        retryMessageSendingGuidStringVoidReceivedInvocations.append(guid)
        retryMessageSendingGuidStringVoidClosure?(guid)
    }

    //MARK: - loadInitialMessages

    var loadInitialMessagesVoidCallsCount = 0
    var loadInitialMessagesVoidCalled: Bool {
        return loadInitialMessagesVoidCallsCount > 0
    }
    var loadInitialMessagesVoidClosure: (() -> Void)?

    func loadInitialMessages() {
        loadInitialMessagesVoidCallsCount += 1
        loadInitialMessagesVoidClosure?()
    }

    //MARK: - didAppear

    var didAppearVoidCallsCount = 0
    var didAppearVoidCalled: Bool {
        return didAppearVoidCallsCount > 0
    }
    var didAppearVoidClosure: (() -> Void)?

    func didAppear() {
        didAppearVoidCallsCount += 1
        didAppearVoidClosure?()
    }

    //MARK: - sendMessage

    var sendMessageSenderContentSenderCompletionBoolVoidVoidCallsCount = 0
    var sendMessageSenderContentSenderCompletionBoolVoidVoidCalled: Bool {
        return sendMessageSenderContentSenderCompletionBoolVoidVoidCallsCount > 0
    }
    var sendMessageSenderContentSenderCompletionBoolVoidVoidClosure: ((ContentSender, ((Bool) -> Void)?) -> Void)?

    func sendMessage(sender: ContentSender, completion: ((Bool) -> Void)?) {
        sendMessageSenderContentSenderCompletionBoolVoidVoidCallsCount += 1
        sendMessageSenderContentSenderCompletionBoolVoidVoidClosure?(sender, completion)
    }

    //MARK: - sendMessage

    var sendMessageMessageMessageSenderContentSenderCompletionBoolVoidVoidCallsCount = 0
    var sendMessageMessageMessageSenderContentSenderCompletionBoolVoidVoidCalled: Bool {
        return sendMessageMessageMessageSenderContentSenderCompletionBoolVoidVoidCallsCount > 0
    }
    var sendMessageMessageMessageSenderContentSenderCompletionBoolVoidVoidClosure: ((Message?, ContentSender, ((Bool) -> Void)?) -> Void)?

    func sendMessage(_ message: Message?, sender: ContentSender, completion: ((Bool) -> Void)?) {
        sendMessageMessageMessageSenderContentSenderCompletionBoolVoidVoidCallsCount += 1
        sendMessageMessageMessageSenderContentSenderCompletionBoolVoidVoidClosure?(message, sender, completion)
    }

    //MARK: - saveDraft

    var saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidCallsCount = 0
    var saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidCalled: Bool {
        return saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidCallsCount > 0
    }
    var saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidReceivedArguments: (messageGUID: String, messageStatus: MessageStatus, text: String, attachments: [ContentSender])?
    var saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidReceivedInvocations: [(messageGUID: String, messageStatus: MessageStatus, text: String, attachments: [ContentSender])] = []
    var saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidClosure: ((String, MessageStatus, String, [ContentSender]) -> Void)?

    func saveDraft(messageGUID: String, messageStatus: MessageStatus, text: String, attachments: [ContentSender]) {
        saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidCallsCount += 1
        saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidReceivedArguments = (messageGUID: messageGUID, messageStatus: messageStatus, text: text, attachments: attachments)
        saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidReceivedInvocations.append((messageGUID: messageGUID, messageStatus: messageStatus, text: text, attachments: attachments))
        saveDraftMessageGUIDStringMessageStatusMessageStatusTextStringAttachmentsContentSenderVoidClosure?(messageGUID, messageStatus, text, attachments)
    }


}

class MessageServiceProtocolMock: MessageServiceProtocol {




    //MARK: - makeMessagesProvider

    var makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolCallsCount = 0
    var makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolCalled: Bool {
        return makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolCallsCount > 0
    }
    var makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolReceivedArguments: (channelID: String, messageTypesToIgnore: [MessageType])?
    var makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolReceivedInvocations: [(channelID: String, messageTypesToIgnore: [MessageType])] = []
    var makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolReturnValue: MessagesProviderProtocol!
    var makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolClosure: ((String, [MessageType]) -> MessagesProviderProtocol)?

    func makeMessagesProvider(channelID: String, messageTypesToIgnore: [MessageType]) -> MessagesProviderProtocol {
        makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolCallsCount += 1
        makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolReceivedArguments = (channelID: channelID, messageTypesToIgnore: messageTypesToIgnore)
        makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolReceivedInvocations.append((channelID: channelID, messageTypesToIgnore: messageTypesToIgnore))
        if let makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolClosure = makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolClosure {
            return makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolClosure(channelID, messageTypesToIgnore)
        } else {
            return makeMessagesProviderChannelIDStringMessageTypesToIgnoreMessageTypeMessagesProviderProtocolReturnValue
        }
    }

    //MARK: - send

    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount = 0
    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidCalled: Bool {
        return sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount > 0
    }
    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedArguments: (guid: String, channelID: String, content: MessageContent, contentMeta: ContentMeta?, replyTo: String?, completion: (Result<Void, Swift.Error>) -> Void)?
    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedInvocations: [(guid: String, channelID: String, content: MessageContent, contentMeta: ContentMeta?, replyTo: String?, completion: (Result<Void, Swift.Error>) -> Void)] = []
    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidClosure: ((String, String, MessageContent, ContentMeta?, String?, @escaping (Result<Void, Swift.Error>) -> Void) -> Void)?

    func send(guid: String, channelID: String, content: MessageContent, contentMeta: ContentMeta?, replyTo: String?, completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount += 1
        sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedArguments = (guid: guid, channelID: channelID, content: content, contentMeta: contentMeta, replyTo: replyTo, completion: completion)
        sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedInvocations.append((guid: guid, channelID: channelID, content: content, contentMeta: contentMeta, replyTo: replyTo, completion: completion))
        sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidClosure?(guid, channelID, content, contentMeta, replyTo, completion)
    }

    //MARK: - update

    var updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount = 0
    var updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidCalled: Bool {
        return updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount > 0
    }
    var updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedArguments: (guids: [String], status: MessageStatus, completion: (Result<Void, Swift.Error>) -> Void)?
    var updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedInvocations: [(guids: [String], status: MessageStatus, completion: (Result<Void, Swift.Error>) -> Void)] = []
    var updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidClosure: (([String], MessageStatus, @escaping (Result<Void, Swift.Error>) -> Void) -> Void)?

    func update(guids: [String], status: MessageStatus, completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount += 1
        updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedArguments = (guids: guids, status: status, completion: completion)
        updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedInvocations.append((guids: guids, status: status, completion: completion))
        updateGuidsStringStatusMessageStatusCompletionEscapingResultVoidSwiftErrorVoidVoidClosure?(guids, status, completion)
    }


}
class MessagesClientProtocolMock: MessagesClientProtocol {




    //MARK: - create

    var createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskThrowableError: (any Error)?
    var createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskCallsCount = 0
    var createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskCalled: Bool {
        return createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskCallsCount > 0
    }
    var createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskReceivedArguments: (message: Message, time: Int, completion: APIResultCallback<CreateMessageResponse>)?
    var createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskReceivedInvocations: [(message: Message, time: Int, completion: APIResultCallback<CreateMessageResponse>)] = []
    var createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskReturnValue: URLSessionTask?
    var createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskClosure: ((Message, Int, @escaping APIResultCallback<CreateMessageResponse>) throws -> URLSessionTask?)?

    func create(message: Message, time: Int, completion: @escaping APIResultCallback<CreateMessageResponse>) throws -> URLSessionTask? {
        createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskCallsCount += 1
        createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskReceivedArguments = (message: message, time: time, completion: completion)
        createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskReceivedInvocations.append((message: message, time: time, completion: completion))
        if let error = createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskThrowableError {
            throw error
        }
        if let createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskClosure = createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskClosure {
            return try createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskClosure(message, time, completion)
        } else {
            return createMessageMessageTimeIntCompletionEscapingAPIResultCallbackCreateMessageResponseURLSessionTaskReturnValue
        }
    }

    //MARK: - retrieve

    var retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskThrowableError: (any Error)?
    var retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskCallsCount = 0
    var retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskCalled: Bool {
        return retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskCallsCount > 0
    }
    var retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskReceivedArguments: (channelID: String?, guid: String?, limit: Int?, time: Int, fromTime: Int?, toTime: Int?, direction: MessagesLoadDirection, completion: APIResultCallback<MessagesResponse>)?
    var retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskReceivedInvocations: [(channelID: String?, guid: String?, limit: Int?, time: Int, fromTime: Int?, toTime: Int?, direction: MessagesLoadDirection, completion: APIResultCallback<MessagesResponse>)] = []
    var retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskReturnValue: URLSessionTask?
    var retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskClosure: ((String?, String?, Int?, Int, Int?, Int?, MessagesLoadDirection, @escaping APIResultCallback<MessagesResponse>) throws -> URLSessionTask?)?

    func retrieve(channelID: String?, guid: String?, limit: Int?, time: Int, fromTime: Int?, toTime: Int?, direction: MessagesLoadDirection, completion: @escaping APIResultCallback<MessagesResponse>) throws -> URLSessionTask? {
        retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskCallsCount += 1
        retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskReceivedArguments = (channelID: channelID, guid: guid, limit: limit, time: time, fromTime: fromTime, toTime: toTime, direction: direction, completion: completion)
        retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskReceivedInvocations.append((channelID: channelID, guid: guid, limit: limit, time: time, fromTime: fromTime, toTime: toTime, direction: direction, completion: completion))
        if let error = retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskThrowableError {
            throw error
        }
        if let retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskClosure = retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskClosure {
            return try retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskClosure(channelID, guid, limit, time, fromTime, toTime, direction, completion)
        } else {
            return retrieveChannelIDStringGuidStringLimitIntTimeIntFromTimeIntToTimeIntDirectionMessagesLoadDirectionCompletionEscapingAPIResultCallbackMessagesResponseURLSessionTaskReturnValue
        }
    }

    //MARK: - update

    var updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskThrowableError: (any Error)?
    var updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskCallsCount = 0
    var updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskCalled: Bool {
        return updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskCallsCount > 0
    }
    var updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskReceivedArguments: (guids: [String], status: MessageStatus, completion: APIResultCallback<MessagesUpdateResponse>)?
    var updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskReceivedInvocations: [(guids: [String], status: MessageStatus, completion: APIResultCallback<MessagesUpdateResponse>)] = []
    var updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskReturnValue: URLSessionTask?
    var updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskClosure: (([String], MessageStatus, @escaping APIResultCallback<MessagesUpdateResponse>) throws -> URLSessionTask?)?

    func update(guids: [String], status: MessageStatus, completion: @escaping APIResultCallback<MessagesUpdateResponse>) throws -> URLSessionTask? {
        updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskCallsCount += 1
        updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskReceivedArguments = (guids: guids, status: status, completion: completion)
        updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskReceivedInvocations.append((guids: guids, status: status, completion: completion))
        if let error = updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskThrowableError {
            throw error
        }
        if let updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskClosure = updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskClosure {
            return try updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskClosure(guids, status, completion)
        } else {
            return updateGuidsStringStatusMessageStatusCompletionEscapingAPIResultCallbackMessagesUpdateResponseURLSessionTaskReturnValue
        }
    }


}
class MessagesProviderProtocolMock: MessagesProviderProtocol {


    var displayableMessages: [Message] = []


    //MARK: - loadInitialMessages

    var loadInitialMessagesCompletionMessagesProviderCallbackVoidCallsCount = 0
    var loadInitialMessagesCompletionMessagesProviderCallbackVoidCalled: Bool {
        return loadInitialMessagesCompletionMessagesProviderCallbackVoidCallsCount > 0
    }
    var loadInitialMessagesCompletionMessagesProviderCallbackVoidClosure: ((MessagesProviderCallback?) -> Void)?

    func loadInitialMessages(completion: MessagesProviderCallback?) {
        loadInitialMessagesCompletionMessagesProviderCallbackVoidCallsCount += 1
        loadInitialMessagesCompletionMessagesProviderCallbackVoidClosure?(completion)
    }

    //MARK: - loadOlderMessages

    var loadOlderMessagesCompletionMessagesProviderCallbackVoidCallsCount = 0
    var loadOlderMessagesCompletionMessagesProviderCallbackVoidCalled: Bool {
        return loadOlderMessagesCompletionMessagesProviderCallbackVoidCallsCount > 0
    }
    var loadOlderMessagesCompletionMessagesProviderCallbackVoidClosure: ((MessagesProviderCallback?) -> Void)?

    func loadOlderMessages(completion: MessagesProviderCallback?) {
        loadOlderMessagesCompletionMessagesProviderCallbackVoidCallsCount += 1
        loadOlderMessagesCompletionMessagesProviderCallbackVoidClosure?(completion)
    }

    //MARK: - loadNewerMessages

    var loadNewerMessagesCompletionMessagesProviderCallbackVoidCallsCount = 0
    var loadNewerMessagesCompletionMessagesProviderCallbackVoidCalled: Bool {
        return loadNewerMessagesCompletionMessagesProviderCallbackVoidCallsCount > 0
    }
    var loadNewerMessagesCompletionMessagesProviderCallbackVoidClosure: ((MessagesProviderCallback?) -> Void)?

    func loadNewerMessages(completion: MessagesProviderCallback?) {
        loadNewerMessagesCompletionMessagesProviderCallbackVoidCallsCount += 1
        loadNewerMessagesCompletionMessagesProviderCallbackVoidClosure?(completion)
    }

    //MARK: - saveMessage

    var saveMessageMessageMessageMessagesProviderCallbackDataCallsCount = 0
    var saveMessageMessageMessageMessagesProviderCallbackDataCalled: Bool {
        return saveMessageMessageMessageMessagesProviderCallbackDataCallsCount > 0
    }
    var saveMessageMessageMessageMessagesProviderCallbackDataReceivedMessage: (Message)?
    var saveMessageMessageMessageMessagesProviderCallbackDataReceivedInvocations: [(Message)] = []
    var saveMessageMessageMessageMessagesProviderCallbackDataReturnValue: MessagesProviderCallbackData!
    var saveMessageMessageMessageMessagesProviderCallbackDataClosure: ((Message) -> MessagesProviderCallbackData)?

    @discardableResult
    func saveMessage(_ message: Message) -> MessagesProviderCallbackData {
        saveMessageMessageMessageMessagesProviderCallbackDataCallsCount += 1
        saveMessageMessageMessageMessagesProviderCallbackDataReceivedMessage = message
        saveMessageMessageMessageMessagesProviderCallbackDataReceivedInvocations.append(message)
        if let saveMessageMessageMessageMessagesProviderCallbackDataClosure = saveMessageMessageMessageMessagesProviderCallbackDataClosure {
            return saveMessageMessageMessageMessagesProviderCallbackDataClosure(message)
        } else {
            return saveMessageMessageMessageMessagesProviderCallbackDataReturnValue
        }
    }

    //MARK: - deleteMessage

    var deleteMessageMessageMessageMessagesProviderCallbackDataCallsCount = 0
    var deleteMessageMessageMessageMessagesProviderCallbackDataCalled: Bool {
        return deleteMessageMessageMessageMessagesProviderCallbackDataCallsCount > 0
    }
    var deleteMessageMessageMessageMessagesProviderCallbackDataReceivedMessage: (Message)?
    var deleteMessageMessageMessageMessagesProviderCallbackDataReceivedInvocations: [(Message)] = []
    var deleteMessageMessageMessageMessagesProviderCallbackDataReturnValue: MessagesProviderCallbackData!
    var deleteMessageMessageMessageMessagesProviderCallbackDataClosure: ((Message) -> MessagesProviderCallbackData)?

    @discardableResult
    func deleteMessage(_ message: Message) -> MessagesProviderCallbackData {
        deleteMessageMessageMessageMessagesProviderCallbackDataCallsCount += 1
        deleteMessageMessageMessageMessagesProviderCallbackDataReceivedMessage = message
        deleteMessageMessageMessageMessagesProviderCallbackDataReceivedInvocations.append(message)
        if let deleteMessageMessageMessageMessagesProviderCallbackDataClosure = deleteMessageMessageMessageMessagesProviderCallbackDataClosure {
            return deleteMessageMessageMessageMessagesProviderCallbackDataClosure(message)
        } else {
            return deleteMessageMessageMessageMessagesProviderCallbackDataReturnValue
        }
    }


}
class SendMessageServiceProtocolMock: SendMessageServiceProtocol {




    //MARK: - send

    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount = 0
    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidCalled: Bool {
        return sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount > 0
    }
    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedArguments: (guid: String, channelID: String, content: MessageContent, contentMeta: ContentMeta?, replyTo: String?, completion: (Result<Void, Swift.Error>) -> Void)?
    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedInvocations: [(guid: String, channelID: String, content: MessageContent, contentMeta: ContentMeta?, replyTo: String?, completion: (Result<Void, Swift.Error>) -> Void)] = []
    var sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidClosure: ((String, String, MessageContent, ContentMeta?, String?, @escaping (Result<Void, Swift.Error>) -> Void) -> Void)?

    func send(guid: String, channelID: String, content: MessageContent, contentMeta: ContentMeta?, replyTo: String?, completion: @escaping (Result<Void, Swift.Error>) -> Void) {
        sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidCallsCount += 1
        sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedArguments = (guid: guid, channelID: channelID, content: content, contentMeta: contentMeta, replyTo: replyTo, completion: completion)
        sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidReceivedInvocations.append((guid: guid, channelID: channelID, content: content, contentMeta: contentMeta, replyTo: replyTo, completion: completion))
        sendGuidStringChannelIDStringContentMessageContentContentMetaContentMetaReplyToStringCompletionEscapingResultVoidSwiftErrorVoidVoidClosure?(guid, channelID, content, contentMeta, replyTo, completion)
    }


}
class WebSocketClientProtocolMock: WebSocketClientProtocol {


    var isConnected: Bool {
        get { return underlyingIsConnected }
        set(value) { underlyingIsConnected = value }
    }
    var underlyingIsConnected: (Bool)!
    var onChannelUpdate: (((String) -> Void)?)
    var onConnect: ((() -> Void)?)
    var onDisconnect: (((Error?) -> Void)?)


    //MARK: - connect

    var connectVoidCallsCount = 0
    var connectVoidCalled: Bool {
        return connectVoidCallsCount > 0
    }
    var connectVoidClosure: (() -> Void)?

    func connect() {
        connectVoidCallsCount += 1
        connectVoidClosure?()
    }

    //MARK: - disconnect

    var disconnectVoidCallsCount = 0
    var disconnectVoidCalled: Bool {
        return disconnectVoidCallsCount > 0
    }
    var disconnectVoidClosure: (() -> Void)?

    func disconnect() {
        disconnectVoidCallsCount += 1
        disconnectVoidClosure?()
    }


}
