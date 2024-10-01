import UIKit

struct VideoContent: MessageContent {
    static let messageType = MessageType.video

    var replyPreview = "video".localized

    var rawContent: String { self.content.path ?? "video".localized }

    var messageGUID: String?
    var content: Content

    init(messageGUID: String? = nil, content: Content) {
        self.messageGUID = messageGUID
        self.content = content
    }

    static func decode(from decoder: Decoder) throws -> Self {
        do {
            let container = try decoder.singleValueContainer()
            let path = try container.decode(String.self)
            return Self(content: Content(path: path, progress: nil, size: nil, image: nil))
        } catch {
            throw ContentTypeError.decodingFailed
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        do {
            try container.encode(self.content.path ?? "")
        } catch {
            throw ContentTypeError.encodingFailed
        }
    }

    // MARK: - Content

    struct Content {
        var path: String?
        var progress: Float?
        let size: CGSize?
        let image: UIImage?

        var isUploaded: Bool {
            return self.path != nil
        }

        func copyUpdating(progress: Float?) -> Self {
            var newContent = self
            newContent.progress = progress
            return newContent
        }
    }
}
