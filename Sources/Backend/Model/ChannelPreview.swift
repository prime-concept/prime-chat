import Foundation

public struct ChannelPreview {
    public let id: String
    public let unreadCount: Int
    public var lastMessagePreview: MessagePreview?

    public init(id: String, unreadCount: Int, lastMessagePreview: MessagePreview? = nil) {
        self.id = id
        self.unreadCount = unreadCount
        self.lastMessagePreview = lastMessagePreview
    }
}
