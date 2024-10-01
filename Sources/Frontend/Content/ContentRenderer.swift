import UIKit

/// Action on Message in Chat: retry, reply
public struct ContentRendererActions {
    var onRetry: (() -> Void)?
    var onReply: (() -> Void)?
    var onLongPress: (() -> Void)?
    var openContent: ((@escaping MessageContentOpeningCompletion) -> Void)?
}

/// Presenter's dependencies
public struct ContentRendererDependencies {
    var chatDelegate: ChatDelegateProtocol?
    var cacheService: CacheServiceProtocol
    var fileService: FileServiceProtocol
    var locationService: LocationServiceProtocol
    var voiceMessageService: VoiceMessageServiceProtocol
}

/// Interface for module which is able to display specific `MessageContent`
public protocol ContentRenderer: AnyObject {
    /// Associated content type
    static var messageContentType: MessageContent.Type { get }

    /// Associated message container model type
    static var messageModelType: MessageModel.Type { get }

    /// Initialize presenter with given content type
    static func make(
        for content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) -> ContentRenderer

    /// Adapt view and view context (meta-info, callbacks, etc) with stored content
    func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel

    /// Create and load a preview for last message in channel
    func preview() -> MessagePreview.ProcessedContent?
}

public class ContentRendererCache {
    private init() { }

    public static let shared: ContentRendererCache = {
        Notification.onReceive(.shouldClearCache, .loggedOut) { _ in
            ContentRendererCache.shared.values.removeAll()
        }

        return ContentRendererCache()
    }()

    @ThreadSafe /* Message UUID to ContentRenderer */
    public var values = [String: ContentRenderer]()
}
