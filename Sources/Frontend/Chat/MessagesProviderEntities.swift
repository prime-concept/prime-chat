import Foundation

public typealias MessagesProviderCallback = (MessagesProviderCallbackData) -> Void

public struct MessagesProviderCallbackData {
    let messages: [Message]

    var direction: MessagesLoadDirection?

    var deleted: IndexSet = []
    var inserted: IndexSet = []
    var updated: IndexSet = []

    var isFromCache: Bool = false
    var hasOlderMessages: Bool = false

    var isLoading: Bool = false
    var error: Swift.Error?
}

struct TimedGUID: Codable {
    let timestamp: Int
    let guid: String

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYY/MM/dd hh:mm:ss"
        let date = Date(timeIntervalSince1970: Double(timestamp))
        return formatter.string(from: date)
    }
}
