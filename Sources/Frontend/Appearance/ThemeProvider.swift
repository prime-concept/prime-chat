import Foundation

public protocol ThemeUpdatable: AnyObject {
    func update(with theme: Theme)
}

final class ThemeProvider {
    enum Notification {
        static let didThemeUpdate = Foundation.Notification.Name("ChatDidThemeUpdate")
    }

    private var onThemeUpdate: ((Theme) -> Void)?
    private weak var themeUpdatable: ThemeUpdatable?

    // swiftlint:disable:next implicitly_unwrapped_optional
    private static var currentScheme: Theme!

    static var current: Theme {
        get {
            if self.currentScheme == nil {
                fatalError("Theme should be specified before use")
            }
            return self.currentScheme
        }
        set {
            self.currentScheme = newValue
            NotificationCenter.default.post(name: Notification.didThemeUpdate, object: nil)
        }
    }

    var current: Theme {
        return Self.current
    }

    init(onThemeUpdate: @escaping (Theme) -> Void, immediateUpdateAfterInit: Bool = true) {
        self.onThemeUpdate = onThemeUpdate

        if immediateUpdateAfterInit {
            onThemeUpdate(Self.current)
        }

        self.subscribe()
    }

    init(themeUpdatable: ThemeUpdatable, immediateUpdateAfterInit: Bool = true) {
        self.themeUpdatable = themeUpdatable

        if immediateUpdateAfterInit {
            themeUpdatable.update(with: Self.current)
        }

        self.subscribe()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func subscribe() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleThemeUpdate),
            name: Notification.didThemeUpdate,
            object: nil
        )
    }

    @objc
    private func handleThemeUpdate() {
        self.onThemeUpdate?(Self.current)
        self.themeUpdatable?.update(with: Self.current)
    }
}
