import Foundation

struct ContactContent: MessageContent {
    static let messageType = MessageType.contact

    var replyPreview = "contact".localized

    var messageGUID: String?
    let content: Content

    var rawContent: String {
        switch self.content {
        case .remote(let path):
            return path
        default:
            return "contact".localized
        }
    }

    init(messageGUID: String? = nil, content: Content) {
        self.messageGUID = messageGUID
        self.content = content
    }

    static func decode(from decoder: Decoder) throws -> Self {
        do {
            let container = try decoder.singleValueContainer()
            return try Self(content: .remote(path: container.decode(String.self)))
        } catch {
            throw ContentTypeError.decodingFailed
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        do {
            if case .remote(let path) = self.content {
                try container.encode(path)
            } else {
                throw ContentTypeError.encodingFailed
            }
        } catch {
            throw ContentTypeError.encodingFailed
        }
    }

    // MARK: - Enums

    enum Content {
        case remote(path: String)
        case local(content: Data)
    }
}
