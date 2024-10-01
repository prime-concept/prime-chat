import UIKit

/// Model represents data for previewing `MessageContent` attachment
public struct AttachmentPreview {
    let id: String
    let previewImage: UIImage
    let mediaAssetType: MediaAssetType
    let duration: Double?
}

/// Interface for abstract entity which is able to send specific `MessageContent`
public protocol ContentSender {
    /// Sending message GUID
    var messageGUID: String { get }

    var content: MessageContent? { get }
    
    var contentPreview: MessagePreview.Content { get }
    /// Model for previewing `MessageContent` reply
    var replyPreview: ReplyPreview? { get }
    /// Model for previewing `MessageContent` attachment
    var attachmentPreview: AttachmentPreview? { get }

    /// Send method and receive content updates during upload
    func send(
        channelID: String,
        using dependencies: ContentSenderDependencies,
        updates: @escaping (MessageContent, ContentMeta) -> Void,
        completion: @escaping (Result<MessageContent, Error>) -> Void
    )

    /// Restore cached draft content sender
    static func from(
        draftAttachment: DraftAttachment,
        dependencies: ContentSenderDependencies
    ) -> ContentSender?

    /// Serialize info about sender for draft caching
    func makeDraftAttachment(with dependencies: ContentSenderDependencies) -> DraftAttachment?
}

extension ContentSender {
    var attachmentPreview: AttachmentPreview? { nil }

    var replyPreview: ReplyPreview? { nil }
}

extension ContentSender {
    var messagePreview: MessagePreview {
        MessagePreview(
            guid: self.messageGUID,
            channelID: "to be filled",
            clientID: nil,
            source: .chat,
            status: .new,
            ttl: nil,
            timestamp: Date(),
            content: [self.contentPreview],
            isIncome: false
        )
    }
}

/// Sender's dependencies
public struct ContentSenderDependencies {
    let sendMessageService: SendMessageServiceProtocol
    let fileService: FileServiceProtocol
    let cacheService: CacheServiceProtocol
}

public final class DummyFileService: FileServiceProtocol {
    func cached<T>(file: FileInfo) -> T? where T: DataInitializable { nil }
    func download(file: FileInfo, skipCache: Bool, completion: @escaping (Data?) -> Void) { }

    func download(
        file: FileInfo,
        skipCache: Bool,
        progress: @escaping ProgressCallback,
        completion: @escaping (URL?) -> Void
    ) { }

    func downloadAndDecode<T>(
        file: FileInfo,
        skipCache: Bool,
        onMainQueue: Bool,
        completion: @escaping (T?) -> Void
    ) where T: DataInitializable { }

    func uploadImmediate(
        filename: String,
        data: Data,
        mimeType: APIClientMimeType,
        completion: @escaping (Result<[UploadedFile], Swift.Error>) -> Void
    ) {}

    func uploadImmediate(
        filename: String,
        data: Data,
        mimeType: APIClientMimeType,
        progress: @escaping ProgressCallback,
        completion: @escaping (Result<[UploadedFile], Swift.Error>) -> Void
    ) {}
}
