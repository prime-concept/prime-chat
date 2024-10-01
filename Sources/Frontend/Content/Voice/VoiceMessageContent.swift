import Foundation

struct VoiceMessageContent: MessageContent {
    static let messageType = MessageType.voiceMessage

    var replyPreview = "voice.message".localized

    var messageGUID: String?
    var content: Content

    var rawContent: String {
        switch self.content {
        case .remote(let path):
            return path.remotePath ?? "voice.message".localized
        default:
            return "voice.message".localized
        }
    }

    init(messageGUID: String? = nil, content: Content) {
        self.messageGUID = messageGUID
        self.content = content
    }

    static func decode(from decoder: Decoder) throws -> Self {
        do {
            let container = try decoder.singleValueContainer()
            let contentPath = try container.decode(String.self)

            guard let file = FileInfo(remotePath: contentPath) else {
                throw Error.invalidFile
            }

            return Self(content: .remote(file: file))
        } catch {
            throw ContentTypeError.decodingFailed
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        do {
            if case .remote(let file) = self.content, let path = file.remotePath {
                try container.encode(path)
            } else {
                throw ContentTypeError.encodingFailed
            }
        } catch {
            throw ContentTypeError.encodingFailed
        }
    }

    // MARK: - Enums

    enum Error: Swift.Error {
        case invalidFile
    }

    enum Content {
        case remote(file: FileInfo)
        case local(content: Data)
    }
}
