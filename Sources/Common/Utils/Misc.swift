import UIKit

func delay(_ delay: TimeInterval, closure: @escaping () -> Void) {
    let deadline = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: deadline, execute: closure)
}

/// Executes async code until some condition is met. If not met, calls the retry token to continue.
/// attempt(every: 5, maxCount: 10){ retry in
///     networkRequest {
///         if error {
///             retry()
///            } else { ... }
///        }
///    }
func attempt(
    after timeout: TimeInterval = 0,
    every seconds: TimeInterval = 0,
    maxCount: UInt? = nil,
    onAttemptsExceeded: (() -> Void)? = nil,
    _ work: @escaping (@escaping () -> Void) -> Void
) {
    var retriesLeft: UInt?
    if let maxCount = maxCount {
        if maxCount == 0 {
            onAttemptsExceeded?()
            return
        }
        retriesLeft = maxCount - 1
    }

    let retrier = {
        delay(seconds) {
            attempt(
                after: 0,
                every: seconds,
                maxCount: retriesLeft,
                onAttemptsExceeded: onAttemptsExceeded,
                work
            )
        }
    }

    delay(timeout) {
        work(retrier)
    }
}

public extension UIView {
    func firstSubviewOf<T: UIView>(type: T.Type) -> T? {
        for subview in subviews {
            if let subview = subview as? T {
                return subview
            }
            if let result = subview.firstSubviewOf(type: T.self) {
                return result
            }
        }

        return nil
    }

    func firstSubview(matching check: (UIView) -> Bool) -> UIView? {
        for subview in subviews {
            if check(subview) {
                return subview
            }
            if let result = subview.firstSubview(matching: check) {
                return result
            }
        }

        return nil
    }
}

extension URL {
    func createWithSubdirectoriesIfNeeded() throws {
        var isDirectory = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory)
        if exists {
            return
        }
        var directoryURL = self
        if !isDirectory.boolValue {
            directoryURL = directoryURL.deletingLastPathComponent()
        }

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
}

extension Array {
    func unique(by comparator: (Element, Element) -> Bool) -> Self {
        var result: Self = []

        self.forEach { item in
            let uniqueItem = result.first { comparator($0, item) }
            if uniqueItem != nil {
                return
            }
            result.append(item)
        }

        return result
    }

    func unique<V>(by keyPath: KeyPath<Element, V>) -> Self where V: Equatable {
        var result: Self = []

        forEach { element in
            let existentElement = result.first {
                let old = $0[keyPath: keyPath]
                let new = element[keyPath: keyPath]
                return old == new
            }

            if existentElement == nil {
                result.append(element)
            }
        }
        return result
    }

    mutating func uniquify<V>(by keyPath: KeyPath<Element, V>) where V: Equatable {
        self = self.unique(by: keyPath)
    }
}

extension UIViewController {
    var topmostPresentedOrSelf: UIViewController {
        var result = self
        while let presented = result.presentedViewController {
            result = presented
        }
        return result
    }
}

extension String {
    func replacing(regex: String, with replacement: String) -> String {
        self.replacingOccurrences(of: regex, with: replacement, options: .regularExpression)
    }

    func stripping(regex: String) -> String {
        self.replacingOccurrences(of: regex, with: "", options: .regularExpression)
    }

    func contains(regex: String) -> Bool {
        self.range(of: regex, options: .regularExpression) != nil
    }
}
