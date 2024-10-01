import Foundation

class MessageContentMock: MessageContent {

    static var messageType = MessageType.text

    static func decode(from decoder: any Decoder) throws -> Self {
        do {
            let container = try decoder.singleValueContainer()
            return try Self(string: container.decode(String.self))
        } catch {
            throw ContentTypeError.decodingFailed
        }
    }

    required init(string: String) {
        self.string = string
    }

    var invokedMessageGUIDSetter = false
    var invokedMessageGUIDSetterCount = 0
    var invokedMessageGUID: String?
    var invokedMessageGUIDList = [String?]()
    var invokedMessageGUIDGetter = false
    var invokedMessageGUIDGetterCount = 0
    var stubbedMessageGUID: String!

    var messageGUID: String? {
        set {
            invokedMessageGUIDSetter = true
            invokedMessageGUIDSetterCount += 1
            invokedMessageGUID = newValue
            invokedMessageGUIDList.append(newValue)
        }
        get {
            invokedMessageGUIDGetter = true
            invokedMessageGUIDGetterCount += 1
            return stubbedMessageGUID
        }
    }

    var invokedStringSetter = false
    var invokedStringSetterCount = 0
    var invokedString: String?
    var invokedStringList = [String]()
    var invokedStringGetter = false
    var invokedStringGetterCount = 0
    var stubbedString: String! = ""

    var string: String {
        set {
            invokedStringSetter = true
            invokedStringSetterCount += 1
            invokedString = newValue
            invokedStringList.append(newValue)
        }
        get {
            invokedStringGetter = true
            invokedStringGetterCount += 1
            return stubbedString
        }
    }

    var invokedReplyPreviewGetter = false
    var invokedReplyPreviewGetterCount = 0
    var stubbedReplyPreview: String! = ""

    var replyPreview: String {
        invokedReplyPreviewGetter = true
        invokedReplyPreviewGetterCount += 1
        return stubbedReplyPreview
    }

    var invokedRawContentGetter = false
    var invokedRawContentGetterCount = 0
    var stubbedRawContent: String! = ""

    var rawContent: String {
        invokedRawContentGetter = true
        invokedRawContentGetterCount += 1
        return stubbedRawContent
    }

    var invokedEncode = false
    var invokedEncodeCount = 0
    var invokedEncodeParameters: (encoder: Encoder, Void)?
    var invokedEncodeParametersList = [(encoder: Encoder, Void)]()
    var stubbedEncodeError: Error?

    func encode(to encoder: Encoder) throws {
        invokedEncode = true
        invokedEncodeCount += 1
        invokedEncodeParameters = (encoder, ())
        invokedEncodeParametersList.append((encoder, ()))
        if let error = stubbedEncodeError {
            throw error
        }
    }
}
