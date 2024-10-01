import UIKit

// Реализован вместо класса KeyboardTracker. Он был очень сложным и бажным.
// Keyboard tracker удален. При необходимости - восстановить из f27386ed112b88f9b9711

public final class KeyboardHeightTracker {
    public var areAnimationsEnabled: Bool = false
    public var isPaused: Bool = true

    private weak var view: UIView?
    public var onKeyboardHeightChanged: (CGFloat) -> Void
    public var onWillShowKeyboard: (() -> Void)?
    public var onWillHideKeyboard: (() -> Void)?

    private var keyboardHeight: CGFloat = 0

    public init(view: UIView, onKeyboardHeightChanged: @escaping (CGFloat) -> Void) {
        self.view = view
        self.onKeyboardHeightChanged = onKeyboardHeightChanged

        self.startListeningToKeyboard()
        self.startListeningToPan()
    }

    private func startListeningToKeyboard() {
        [
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardWillHideNotification
        ].forEach { name in
            NotificationCenter
                .default
                .addObserver(
                    self,
                    selector: #selector(handleKeyboard),
                    name: name,
                    object: nil
                )
        }
        
        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(handleOtherTrackerPan(_:)),
                name: .otherTrackerDidTrackPan,
                object: nil
            )
    }

    private func startListeningToPan() {
        guard let view = self.view,
              let scrollView = view.firstSubviewOf(type: UIScrollView.self),
              scrollView.keyboardDismissMode == .interactive else {
            return
        }

        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
    }

    @objc
    private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let y = recognizer.location(in: self.view).y
        self.didPan(y)
        self.notifyPan(y)
    }
    
    private func didPan(_ y: CGFloat) {
        guard let view = self.view else {
            return
        }
        
        let keyboardOriginY = view.bounds.height - self.keyboardHeight
    
        guard y > keyboardOriginY else {
            return
        }
    
        let delta = y - keyboardOriginY
        let height = max(0, self.keyboardHeight - delta)
        
        self.onKeyboardHeightChanged(height)
    }
    
    @objc
    private func handleKeyboard(notification: NSNotification) {
        guard let view = self.view,
              let window = UIWindow.keyWindow,
              let userInfo = notification.userInfo else {
            return
        }

        let heightUpdate = {
            let frameKey = UIResponder.keyboardFrameEndUserInfoKey
            let keyboardFrame = (userInfo[frameKey] as? NSValue)?.cgRectValue ?? .zero
            let selfFrame = view.convert(view.frame, to: window)

            self.keyboardHeight = 0

            if selfFrame.intersects(keyboardFrame) {
                let intersection = keyboardFrame.intersection(selfFrame)
                self.keyboardHeight = max(0, intersection.size.height)
            }

            self.onKeyboardHeightChanged(self.keyboardHeight)

            if notification.name == UIResponder.keyboardWillShowNotification {
                self.onWillShowKeyboard?()
            } else if notification.name == UIResponder.keyboardWillHideNotification {
                self.onWillHideKeyboard?()
            }

            guard self.areAnimationsEnabled else {
                return
            }

            let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
            let duration = (userInfo[durationKey] as? TimeInterval) ?? 0

            let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey
            let curveRaw = (userInfo[curveKey] as? UInt) ?? 0 << 16

            typealias Curve = UIView.AnimationOptions.Element
            let curve = Curve(rawValue: curveRaw)

            view.setNeedsLayout()
            UIView.animate(withDuration: duration, delay: 0, options: [curve]) {
                view.layoutIfNeeded()
            }
        }

        heightUpdate()
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(heightUpdate)
        CATransaction.commit()
    }
    
    private func notifyPan(_ y: CGFloat) {
        let notification = Notification(
            name: .otherTrackerDidTrackPan,
            object: nil,
            userInfo: [
                "sender": self,
                "y": y
            ]
        )
        NotificationCenter.default.post(notification)
    }
    
    @objc
    private func handleOtherTrackerPan(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let sender = userInfo["sender"] as? KeyboardHeightTracker,
              sender !== self,
              let y = userInfo["y"] as? CGFloat else {
            return
        }
        
        self.didPan(y)
    }
    
    private func updateKeyboardHeight(with keyboardFrame: CGRect) {
        guard let view = self.view,
              let window = UIWindow.keyWindow else {
            return
        }
        let selfFrame = view.convert(view.frame, to: window)
        
        self.keyboardHeight = 0
        
        if selfFrame.intersects(keyboardFrame) {
            let intersection = keyboardFrame.intersection(selfFrame)
            self.keyboardHeight = max(0, intersection.size.height)
        }
    }
}

private extension Notification.Name {
    /// Какой-то другой KeyboardHeightTracker обнаружил изменение высоты.
    /// Он рассылает остальным KHT нотификацию с новым фреймом клавиатуры
    /// в координатах window.
    static let otherTrackerDidTrackPan = Notification.Name("otherTrackerDidTrackPan")
}
