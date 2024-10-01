import UIKit

final class MessageContainerSwipeView: UIView {
    private static let rightInset: CGFloat = 44
    private static let actionTriggerThreshold: CGFloat = 0.6

    private let replyView: UIView = {
        let view = UIView()
        view.bounds.size = CGSize(width: 36, height: 36)
        view.clipsToBounds = true
        view.layer.cornerRadius = view.bounds.height / 2
        return view
    }()

    private let replyIconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.bounds.size = CGSize(width: 15, height: 15)
        return iconView
    }()

    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognized(_:)))
        recognizer.delegate = self
        return recognizer
    }()

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognized(_:)))
        recognizer.delegate = self
        return recognizer
    }()

    private var themeProvider: ThemeProvider?

    private var location: CGFloat = 0
    private var offset: CGFloat = 0

    private var shouldTriggerFeedbackOnThreshold = true

    var onCompletedSwipe: (() -> Void)?
    let contentView = UIView()

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.setupView()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.contentView.frame = self.bounds

        let bounds = self.bounds

        if bounds.isEmpty {
            return
        }

        let replyViewSize = self.replyView.bounds.size
        let viewWidth: CGFloat = Self.rightInset + replyViewSize.width

        self.replyView.alpha = self.offset

        self.contentView.frame = bounds.offsetBy(
            dx: viewWidth * self.offset,
            dy: 0
        )

        let replyX = self.contentView.frame.origin.x - replyViewSize.width
        self.replyView.frame = CGRect(
            origin: CGPoint(x: replyX, y: self.frame.midY - replyViewSize.height / 2),
            size: replyViewSize
        )

        self.replyIconView.center = CGPoint(x: self.replyView.bounds.midX, y: self.replyView.bounds.midY)
    }

    // MARK: - Private

    private func setupView() {
        self.clipsToBounds = true
        self.addSubview(self.contentView)
        self.addSubview(self.replyView)
        self.replyView.addSubview(self.replyIconView)

        self.isExclusiveTouch = true
        self.contentView.isExclusiveTouch = true

        self.contentView.addGestureRecognizer(self.panGestureRecognizer)
        self.contentView.addGestureRecognizer(self.tapGestureRecognizer)
    }

    @objc
    private func panGestureRecognized(_ recognizer: UIPanGestureRecognizer) {
        self.didUpdateGestureState(recognizer)
    }

    @objc
    private func tapGestureRecognized(_ recognizer: UITapGestureRecognizer) {
        self.update(offset: 0, animated: true)
    }

    private func didUpdateGestureState(_ panRecognizer: UIPanGestureRecognizer) {
        let contentView = self.contentView

        switch panRecognizer.state {
        case .began:
            self.location = contentView.frame.minX
        case .changed:
            let translation = panRecognizer.translation(in: contentView).x

            let width: CGFloat = Self.rightInset + self.replyView.bounds.width

            let x = max(0, translation + self.location)

            if x < width {
                self.update(offset: x / width, animated: false)
            } else {
                self.update(offset: pow(CGFloat(M_E), 1 - width / x), animated: false)
            }

            if self.shouldTriggerFeedbackOnThreshold, self.offset >= Self.actionTriggerThreshold {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                self.shouldTriggerFeedbackOnThreshold = false
            }
        default:
            self.shouldTriggerFeedbackOnThreshold = true
            if self.offset >= Self.actionTriggerThreshold {
                self.onCompletedSwipe?()
            }

            self.update(offset: 0.0, animated: true)
        }
    }

    private func update(offset value: CGFloat, animated: Bool) {
        guard (value.isZero || value.isNormal), value >= 0, value != self.offset else {
            return
        }

        self.offset = min(1.0, value)

        self.setNeedsLayout()

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: self.layoutIfNeeded,
                completion: nil
            )
        } else {
            UIView.performWithoutAnimation(self.layoutIfNeeded)
        }
    }
}

extension MessageContainerSwipeView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let contentView = self.contentView

        if let tapRecognizer = gestureRecognizer as? UITapGestureRecognizer, tapRecognizer.view === contentView {
            return self.offset > 0
        }

        if let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer, panRecognizer.view === contentView {
            let translation = panRecognizer.translation(in: contentView)

            return panRecognizer.numberOfTouches == 1 && abs(translation.y) < abs(translation.x)
        }

        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

extension MessageContainerSwipeView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.replyIconView.image = theme.imageSet.replyIcon.withRenderingMode(.alwaysTemplate)
        self.replyIconView.tintColor = theme.palette.replySwipeIcon

        self.replyView.backgroundColor = theme.palette.replySwipeBackground
    }
}
