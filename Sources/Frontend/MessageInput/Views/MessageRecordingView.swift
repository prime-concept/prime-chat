import UIKit

final class MessageRecordingView: UIView {
    private enum Appearance {
        static let timeFont = ThemeProvider.current.fontProvider.voiceMessageRecordingTime
        static let dotViewRadius: CGFloat = 3
        static let swipeToDismissFont = ThemeProvider.current.fontProvider.voiceMessageRecordingTitle
    }

    // MARK: - Private properties

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.timeFont.font
        return label
    }()

    private lazy var recordingIndicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Appearance.dotViewRadius

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [1.0, 1.0, 0.0]
        animation.keyTimes = [0.0, 0.4546, 0.9091, 1]
        animation.duration = 0.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        view.layer.add(animation, forKey: "opacity-dot")

        return view
    }()

    private lazy var slideToCancelIndicatorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var swipeToDismissLabel: UILabel = {
        let label = UILabel()
        label.text = "swipe.to.cancel".localized
        label.font = Appearance.swipeToDismissFont.font
        return label
    }()

    private var themeProvider: ThemeProvider?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.themeProvider = ThemeProvider(themeUpdatable: self)

        self.setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    func update(time: String?) {
        self.timeLabel.text = time == nil ? "0:00:00" : time
    }

    // MARK: - Private methods

    private func setupSubviews() {
        [
            self.recordingIndicatorView,
            self.timeLabel,
            self.slideToCancelIndicatorImageView,
            self.swipeToDismissLabel
        ].forEach(self.addSubview)

        self.recordingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                self.recordingIndicatorView.trailingAnchor.constraint(
                    equalTo: self.timeLabel.leadingAnchor, constant: -5
                ),
                self.recordingIndicatorView.centerYAnchor.constraint(equalTo: self.timeLabel.centerYAnchor),
                self.recordingIndicatorView.widthAnchor.constraint(equalToConstant: 6),
                self.recordingIndicatorView.heightAnchor.constraint(equalToConstant: 6)
            ]
        )

        self.timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                self.timeLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 26),
                self.timeLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ]
        )

        self.slideToCancelIndicatorImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                self.slideToCancelIndicatorImageView.leftAnchor.constraint(
                    equalTo: self.timeLabel.rightAnchor, constant: 5
                ),
                self.slideToCancelIndicatorImageView.widthAnchor.constraint(equalToConstant: 7),
                self.slideToCancelIndicatorImageView.heightAnchor.constraint(equalToConstant: 11),
                self.slideToCancelIndicatorImageView.centerYAnchor.constraint(
                    equalTo: self.swipeToDismissLabel.centerYAnchor
                ),
                self.slideToCancelIndicatorImageView.trailingAnchor.constraint(
                    equalTo: self.swipeToDismissLabel.leadingAnchor, constant: -10
                )
            ]
        )

        self.swipeToDismissLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(
            [
                self.swipeToDismissLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                self.swipeToDismissLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ]
        )
    }
}

// MARK: - ThemeUpdatable

extension MessageRecordingView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.backgroundColor = theme.palette.senderBackground
        self.recordingIndicatorView.backgroundColor = theme.palette.voiceMessageRecordingIndicator
        self.slideToCancelIndicatorImageView.tintColor = theme.palette.voiceMessageRecordingDismissIndicator
        self.slideToCancelIndicatorImageView.image = theme.imageSet.slideToCancelIndicatorIcon
            .withRenderingMode(.alwaysTemplate)
        self.timeLabel.textColor = theme.palette.voiceMessageRecordingTime
        self.swipeToDismissLabel.textColor = theme.palette.voiceMessageRecordingDismissTitle
    }
}
