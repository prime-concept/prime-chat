import Foundation

public protocol DebugLogger {
    func log(sender: AnyObject?, prefix: String, _ items: Any...)
}

private var externalLogger: DebugLogger?
public func acceptExternalLogger(_ logger: DebugLogger) {
    if externalLogger == nil {
        externalLogger = logger
    }
}

public var MAY_LOG_IN_PRINT = true

func log(sender: AnyObject?, _ items: Any...) {
    externalLogger?.log(sender: sender, prefix: "ChatSDK:", items)

    if MAY_LOG_IN_PRINT {
        items.count > 1 ? Swift.print(items) : (items.count == 1 ? Swift.print(items[0]) : Swift.print())
    }
}
