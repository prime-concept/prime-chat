import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private static let queue = DispatchQueue(label: "Monitor")

    private(set) var isConnected: Bool = false
    private lazy var monitor = NWPathMonitor()

    init() {
        self.monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
        }
        self.monitor.start(queue: Self.queue)
    }
}
