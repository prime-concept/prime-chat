import Foundation

struct TextContent: MessageContent {
    static let messageType = MessageType.text

    var replyPreview: String { self.string }

    var rawContent: String { self.string }

    var messageGUID: String?
    let string: String

    init(messageGUID: String? = nil, string: String) {
        self.messageGUID = messageGUID
        self.string = Self.sanitized(string)
    }

    static func decode(from decoder: Decoder) throws -> Self {
        do {
            let container = try decoder.singleValueContainer()
            return try Self(string: container.decode(String.self))
        } catch {
            throw ContentTypeError.decodingFailed
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        do {
            try container.encode(self.string)
        } catch {
            throw ContentTypeError.encodingFailed
        }
    }

    // MARK: - Private

    private static func sanitized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
