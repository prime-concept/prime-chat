import Foundation

struct SubscriptionsResponse: Decodable {
    let channels: [ChannelSubscription]
}
