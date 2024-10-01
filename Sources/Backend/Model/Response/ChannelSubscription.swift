import Foundation

/// Preview-like info about a Channel. Latest message + unread count goes here.
/// Why not to use only a ChannelPreview, why spawning with this struct?
/// That's a VERY good question.
struct ChannelSubscription: Decodable {
    let unread: Int
    let lastMessage: Message?
    let channelId: String
}
