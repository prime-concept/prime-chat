import UIKit
import AudioToolbox

final class MessageRecordingButton: UIButton {
    private enum Appearance {
        static let innerCircleRadius: CGFloat = 100
    }

    var onShouldHandleTouch: (() -> (Bool))?
    var onRecordingStart: (() -> Void)?
    var onRecordingEnd: (() -> Void)?
    var onRecordingCancel: (() -> Void)?

    private lazy var innerCircleView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = Appearance.innerCircleRadius / 2
        imageView.alpha = 0
        return imageView
    }()

    private lazy var innerIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.alpha = 0
        return imageView
    }()

    private lazy var panRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(self.panGesture(_:))
        )
        recognizer.delegate = self
        return recognizer
    }()

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(self.longTapped(_:))
        )
        recognizer.delegate = self
        return recognizer
    }()

    private var themeProvider: ThemeProvider?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.themeProvider = ThemeProvider(themeUpdatable: self)

        self.setupSubviews()
        self.setupRecognizers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        [self.innerCircleView, self.innerIconView].forEach(self.addSubview)

        self.innerCircleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                self.innerCircleView.widthAnchor.constraint(equalToConstant: Appearance.innerCircleRadius),
                self.innerCircleView.heightAnchor.constraint(equalToConstant: Appearance.innerCircleRadius),
                self.innerCircleView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 4),
                self.innerCircleView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 4)
            ]
        )

        self.innerIconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                self.innerIconView.widthAnchor.constraint(equalToConstant: 44),
                self.innerIconView.heightAnchor.constraint(equalToConstant: 44),
                self.innerIconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                self.innerIconView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
            ]
        )
    }

    private func setupRecognizers() {
        [self.panRecognizer, self.longPressRecognizer].forEach(self.addGestureRecognizer)
    }

    @objc
    private func panGesture(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.view != nil && self.longPressRecognizer.state == .changed {
            let translationX = recognizer.translation(in: self).x

            if translationX < -(Appearance.innerCircleRadius / 2 - 3) {
                self.longPressRecognizer.state = .cancelled
            }
        }
    }

    @objc
    private func longTapped(_ gesture: UILongPressGestureRecognizer) {
        guard let onShouldHandleTouch = self.onShouldHandleTouch, onShouldHandleTouch() else {
            return
        }

        if gesture.state == .began {
            self.playFeedback()
            self.animateIn()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.onRecordingStart?()
            }
        }

        if gesture.state == .ended {
            self.animateOut()
            self.onRecordingEnd?()
            self.playFeedback()
        }

        if gesture.state == .cancelled {
            self.animateOut()
            self.onRecordingCancel?()
        }
    }

    private func animateIn() {
        self.innerIconView.transform = CGAffineTransform.identity
        self.innerCircleView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        self.innerCircleView.alpha = 0.2

        UIView.animate(
            withDuration: 0.50,
            delay: 0.0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 0.0,
            options: .beginFromCurrentState,
            animations: {
                self.innerCircleView.transform = CGAffineTransform.identity
            }
        )

        UIView.animate(
            withDuration: 0.1,
            animations: {
                self.innerIconView.transform = CGAffineTransform.identity
                self.imageView?.alpha = 0
                self.innerIconView.alpha = 1.0
                self.innerCircleView.alpha = 1.0
            }
        )
    }

    private func animateOut() {
        UIView.animate(
            withDuration: 0.18,
            animations: {
                self.innerCircleView.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
                self.innerCircleView.alpha = 0.0

                self.imageView?.alpha = 1
                self.innerIconView.alpha = 0.0
            }, completion: nil
        )
    }

    private func playFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MessageRecordingButton: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return (gestureRecognizer == self.panRecognizer) && (otherGestureRecognizer == self.longPressRecognizer)
    }
}

// MARK: - ThemeUpdatable

extension MessageRecordingButton: ThemeUpdatable {
    func update(with theme: Theme) {
        self.innerIconView.image = theme.imageSet.voiceMessageButton.withRenderingMode(.alwaysTemplate)
        self.innerIconView.tintColor = theme.palette.voiceMessageRecordingCircleTint
        self.innerCircleView.backgroundColor = theme.palette.voiceMessageRecordingCircleBackground
    }
}
