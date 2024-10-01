import UIKit

public enum ChatEditingEvent {
    // Last actual message from channel
    case message(MessagePreview)
    // Notification about empty channel
    case empty(channelID: String)
}

public struct MessagePreview {
    public let guid: String
    public let channelID: String
    public let clientID: String?
    public let source: MessageSource
    public let status: MessageStatus
    public let ttl: Date?
    public let timestamp: Date
    public let content: [Content]
    public let isIncome: Bool

    public struct Content {
        /// Ready to display as preview
        public let processed: ProcessedContent?
        public let raw: RawContent
    }

    public struct RawContent {
        public let type: MessageType
        public let content: String
        public let meta: [String: Any]
    }

    /// Types for contents processed in SDK
    /// Ready to display as preview
    public enum ProcessedContent: CustomDebugStringConvertible {
        case text(String)
        case video(preview: AsyncContentProvider<UIImage>?)
        case photo(image: AsyncContentProvider<UIImage>?)
        case voice
        case contact(name: String?)
        case document(name: String?, size: Double?)
        case geo

        public var previewString: String {
            switch self {
            case .text(let string):
                return string
            case .video:
                return "video".localized
            case .photo:
                return "image".localized
            case .voice:
                return "voice.message".localized
            case .contact:
                return "contact".localized
            case .document(let name, _):
                return name ?? "document".localized
            case .geo:
                return "location".localized
            }
        }

        public var debugDescription: String {
            switch self {
            case .text:
                return "Text message"
            case .video:
                return "Video message"
            case .photo:
                return "Photo message"
            case .voice:
                return "Voice message"
            case .contact:
                return "Contact message"
            case .document:
                return "Document message"
            case .geo:
                return "Location message"
            }
        }
    }
}

public extension MessagePreview.ProcessedContent {
    var messageType: MessageType {
        switch self {
        case .text:
            return .text
        case .video:
            return .video
        case .photo:
            return .image
        case .voice:
            return .voiceMessage
        case .contact:
            return .contact
        case .document:
            return .doc
        case .geo:
            return .location
        }
    }
}

public extension MessagePreview {
    static let outcomeStub = MessagePreview(
        guid: "OUTCOME_STUB",
        channelID: "",
        clientID: nil,
        source: .chat,
        status: .unknown,
        ttl: nil,
        timestamp: Date(),
        content: [],
        isIncome: false
    )
}

public struct AsyncContentProvider<T: DataInitializable> {
    private let wrapped: Wrapped<T>

    public init(loader: AsyncContentLoader<T>) {
        self.wrapped = .loader(loader)
    }

    public init(value: T) {
        self.wrapped = .instance(value)
    }

    public func load(completion: @escaping (T?) -> Void) {
        switch self.wrapped {
        case .instance(let value):
            completion(value)
        case .loader(let value):
            value.load(completion: completion)
        }
    }

    enum Wrapped<V: DataInitializable> {
        case loader(AsyncContentLoader<V>)
        case instance(V)
    }
}

public struct AsyncContentLoader<T: DataInitializable> {
    public typealias Content = T

    private let fileService: FileServiceProtocol
    private let fileInfo: FileInfo

    init(fileService: FileServiceProtocol, fileInfo: FileInfo) {
        self.fileService = fileService
        self.fileInfo = fileInfo
    }

    public func load(completion: @escaping (T?) -> Void) {
        self.fileService.downloadAndDecode(
            file: self.fileInfo,
            skipCache: false,
            onMainQueue: false
        ) { (obj: T?) in
            completion(obj)
        }
    }
}
