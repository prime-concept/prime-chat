import Foundation

struct DocumentContent: MessageContent, Codable {
    static let messageType: MessageType = .doc

    var replyPreview = "document".localized

    var rawContent: String {
        let path = self.content.path ?? ""
        if path.isEmpty {
            return "document".localized
        }
        let rawContent = URL(fileURLWithPath: path).lastPathComponent
        return rawContent
    }

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
            let content = Content(path: path)
            let instance = Self.init(content: content)
            return instance
        } catch {
            throw ContentTypeError.decodingFailed
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        do {
            try container.encode(self.content.path)
        } catch {
            throw ContentTypeError.encodingFailed
        }
    }

    // MARK: - Content

    struct Content: Codable {
        internal init(path: String? = nil, progress: Float? = nil, name: String? = nil, size: Double? = nil) {
            self.path = path
            self.progress = progress
            self.name = name
            self.size = size
        }

        var path: String?
        var progress: Float?
        private(set) var name: String?
        private(set) var size: Double?

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
