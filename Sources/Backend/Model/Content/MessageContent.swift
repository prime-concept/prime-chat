import Foundation

// MARK: - MessageContent

public enum MessageType: String, Codable, CaseIterable {
    case text = "TEXT"
    case image = "IMAGE"
    case voiceMessage = "VOICEMESSAGE"
    case video = "VIDEO"
    case location = "LOCATION"
    case contact = "CONTACT"
    case doc = "DOC"
    case taskLink = "TASK_LINK"
}

public protocol MessageContent {
    /// String representation of message type, possible values:
    /// "TEXT" IMAGE" "VOICEMESSAGE" "VIDEO" "LOCATION" "CONTACT" "DOC"
    /// Will be used inside Message object
    static var messageType: MessageType { get }

    var messageGUID: String? { get set }

    /// Short representation of content used for reply
    /// Example: just a text for TEXT, "Голосовое сообщение" for VOICEMESSAGE
    var replyPreview: String { get }

    /// Raw content representation
    var rawContent: String { get }

    /// Decoder.
    /// Throw `MessageTypeError.decodingFailed` to let handle this exception on the layer above.
    static func decode(from decoder: Decoder) throws -> Self

    /// Encoder.
    /// Throw `MessageTypeError.encodingFailed` to let handle this exception on the layer above.
    func encode(to encoder: Encoder) throws
}

public extension MessageContent {
    var messageType: MessageType {
        return Self.messageType
    }

    func encode(to encoder: Encoder) throws {
        throw ContentTypeError.unencodableType
    }
}

// MARK: - ContentTypeFactory

final class MessageContentFactory {
    private var contentTypes: [MessageContent.Type]

    init(contentTypes: [MessageContent.Type]) {
        self.contentTypes = contentTypes
    }

    func registerContentType(_ contentType: MessageContent.Type) {
        self.contentTypes.append(contentType)
    }

    func make(from decoder: Decoder, type: MessageType) throws -> MessageContent? {
        for registeredType in self.contentTypes where registeredType.messageType == type {
            do {
                let messageType = try registeredType.decode(from: decoder)
                return messageType
            } catch {
                let userInfo: [String: Any] = [
                    "sender": "\(type) \(#function)",
                    "error": error,
                    "details": "ContentTypeError.encodingFailed"
                ]

                NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
            }
        }

        return nil
    }
}

// MARK: - ContentTypeError

public enum ContentTypeError: Swift.Error {
    case decodingFailed
    case encodingFailed
    case unencodableType
}
