import UIKit

struct ImageContent: MessageContent {
    static let messageType: MessageType = .image

    var replyPreview = "image".localized

    var messageGUID: String?
    let content: Content

    var rawContent: String { self.content.path ?? "image".localized }

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
        let path: String?
        private(set) var progress: Float?
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
