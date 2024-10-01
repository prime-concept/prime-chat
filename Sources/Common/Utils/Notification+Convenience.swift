import Foundation

extension NotificationCenter {
    func post(_ name: Notification.Name) {
        self.post(name: name, object: nil)
    }

    func post(_ name: Notification.Name, userInfo: [AnyHashable: Any]?) {
        self.post(name: name, object: nil, userInfo: userInfo)
    }
}

extension Notification {
    static func onReceive(
        _ names: Notification.Name...,
        on queue: DispatchQueue = .main,
        uniqueBy owner: AnyObject? = nil,
        handler: @escaping (Notification) -> Void
    ) {
        names.forEach { name in
            let handler: ((Notification) -> Void) = { notification in
                queue.async {
                    handler(notification)
                }
            }

            NotificationHandlersRegistry.register(handler: handler, for: name, uniqueBy: owner)
        }
    }
}

private final class NotificationHandlersRegistry {
    private static var registry: [Notification.Name: [(AnyObject?, (Notification) -> Void)]] = [:]
    private static let registryQueue = DispatchQueue(
        label: "ChatSDK.NotificationHandlersRegistryQueue",
        qos: .userInitiated
    )

    static func register(
        handler: @escaping (Notification) -> Void,
        for key: Notification.Name,
        uniqueBy owner: AnyObject? = nil
    ) {
        self.registryQueue.async {
            var ownerHandlerPair = self.registry[key] ?? []
            if owner != nil {
                for i in 0..<ownerHandlerPair.count where ownerHandlerPair[i].0 === owner {
                    return
                }
            }

            ownerHandlerPair.append((owner, handler))

            self.registry[key] = ownerHandlerPair

            NotificationCenter.default.removeObserver(self, name: key, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(onReceive(_:)), name: key, object: nil)
        }
    }

    @objc
    static func onReceive(_ notification: Notification) {
        self.registryQueue.async {
            self.registry[notification.name]?.forEach { ownerHandlerPair in
                let handler = ownerHandlerPair.1
                handler(notification)
            }
        }
    }
}
