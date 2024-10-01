import Foundation
import CoreLocation

struct LocationContent: MessageContent {
    static let messageType = MessageType.location

    var replyPreview = "location".localized

    var rawContent: String {
        switch self.content {
        case .remote(let path):
            return path
        default:
            return "location".localized
        }
    }

    var messageGUID: String?
    let content: Content

    init(messageGUID: String? = nil, content: Content) {
        self.messageGUID = messageGUID
        self.content = content
    }

    static func decode(from decoder: Decoder) throws -> Self {
        do {
            let container = try decoder.singleValueContainer()
            let contentPath = try container.decode(String.self)

            return Self(content: .remote(path: contentPath))
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
        case local(point: CLLocationCoordinate2D)
    }
}
