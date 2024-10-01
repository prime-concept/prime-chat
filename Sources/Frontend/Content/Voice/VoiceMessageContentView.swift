import UIKit

final class VoiceMessageContentView: UIView {
    var guid: String?
    
    private enum Appearance {
        static let playButtonInsets = UIEdgeInsets(top: 9, left: 9, bottom: 9, right: 12)
        static let playButtonSize = CGSize(width: 36, height: 36)
        static let progressHeight: CGFloat = 3.0
        static let progressRightInset: CGFloat = 8.0
        static let timeTopInset: CGFloat = 3.0
        static let timeHeight: CGFloat = 13
    }

    // MARK: - View model
    struct Model {
        let status: Status
        let time: Int
        let duration: Int?

        enum Status {
            case error
            case playing
            case paused
            case waiting
        }
    }

    static var height: CGFloat = 54.0

    func play() {
        self.playButton.sendActions(for: .touchUpInside)
    }

    private lazy var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.playButtonClicked), for: .touchUpInside)
        return button
    }()

    private lazy var progressView = UIProgressView(progressViewStyle: .default)
    private lazy var scrubberView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didScrub(_:)))
        view.addGestureRecognizer(panRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didScrub(_:)))
        view.addGestureRecognizer(tapRecognizer)

        return view
    }()

    private lazy var timeLabel = UILabel()

    private lazy var waitingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        return view
    }()

    private var infoViewFrame: CGRect?
    private var themeProvider: ThemeProvider?
    var onPlayButtonClick: (() -> Void)?
    var onScrub: ((Double) -> Void)?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.setupSubviews()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.playButton.frame = CGRect(
            x: Appearance.playButtonInsets.left,
            y: Appearance.playButtonInsets.top,
            width: Appearance.playButtonSize.width,
            height: Appearance.playButtonSize.height
        )

        self.waitingIndicatorView.center = self.playButton.center

        self.progressView.frame = CGRect(
            x: self.playButton.frame.maxX + Appearance.playButtonInsets.right,
            y: self.bounds.midY - (Appearance.progressHeight / 2).rounded(),
            width: self.bounds.width
            - self.playButton.frame.maxX
            - Appearance.playButtonInsets.right
            - Appearance.progressRightInset,
            height: Appearance.progressHeight
        )

        self.timeLabel.frame = CGRect(
            x: self.progressView.frame.minX,
            y: self.progressView.frame.maxY + Appearance.timeTopInset,
            width: (self.infoViewFrame?.minX ?? self.bounds.width)
            - self.playButton.frame.maxX
            - Appearance.playButtonInsets.right
            - Appearance.progressRightInset,
            height: Appearance.timeHeight
        )

        self.scrubberView.frame = CGRect(
            x: self.progressView.frame.minX,
            y: 0,
            width: self.progressView.bounds.width,
            height: self.frame.height
        )
    }

    func update(with model: Model, meta: MessageContainerModelMeta) {
        guard let theme = self.themeProvider?.current else {
            return
        }

        self.playButton.backgroundColor = meta.author == .me
        ? theme.palette.voiceMessageOutcomePlayBackground
        : theme.palette.voiceMessageIncomePlayBackground
        self.progressView.progressTintColor = meta.author == .me
        ? theme.palette.voiceMessageOutcomeProgressMain
        : theme.palette.voiceMessageIncomeProgressMain
        self.progressView.trackTintColor = meta.author == .me
        ? theme.palette.voiceMessageOutcomeProgressSecondary
        : theme.palette.voiceMessageIncomeProgressSecondary
        self.timeLabel.textColor = meta.author == .me
        ? theme.palette.voiceMessageOutcomeTime
        : theme.palette.voiceMessageIncomeTime
        let timeString: String = {
            guard let duration = model.duration else {
                return "-:-"
            }

            var time = model.time

            if model.status == .paused && time == 0 {
                time = duration
            }

            let minutes = Int(time / 60)
            let seconds = Int(time % 60)
            let timeString = "\(minutes)" + ":" + (seconds >= 10 ? "\(seconds)" : "0\(seconds)")
            return timeString
        }()

        self.timeLabel.set(text: timeString, with: theme.fontProvider.voiceMessageDuration)

        if let duration = model.duration {
            let progress = Float(model.time) / max(1.0, Float(duration))
            self.progressView.setProgress(progress, animated: false)
        }

        self.scrubberView.isHidden = model.status != .playing

        switch model.status {
        case .error:
            self.waitingIndicatorView.stopAnimating()
            self.playButton.isEnabled = false
            self.playButton.setImage(
                theme.imageSet.voiceMessagePlayButton.withRenderingMode(.alwaysTemplate),
                for: .normal
            )

        case .paused:
            self.waitingIndicatorView.stopAnimating()
            self.playButton.isEnabled = true
            self.playButton.setImage(
                theme.imageSet.voiceMessagePlayButton.withRenderingMode(.alwaysTemplate),
                for: .normal
            )

        case .playing:
            self.waitingIndicatorView.stopAnimating()
            self.playButton.isEnabled = true
            self.playButton.setImage(
                theme.imageSet.voiceMessagePauseButton.withRenderingMode(.alwaysTemplate),
                for: .normal
            )

        case .waiting:
            self.waitingIndicatorView.startAnimating()
            self.playButton.isEnabled = false
            self.playButton.setImage(UIImage(), for: .normal)
        }
    }

    // MARK: - Private

    private func setupSubviews() {
        self.addSubview(self.playButton)
        self.playButton.clipsToBounds = true
        self.playButton.layer.cornerRadius = (Appearance.playButtonSize.width / 2).rounded()

        self.addSubview(self.progressView)
        self.progressView.clipsToBounds = true
        self.progressView.layer.cornerRadius = (Appearance.progressHeight / 2).rounded()

        self.addSubview(self.timeLabel)
        self.addSubview(self.waitingIndicatorView)

        self.addSubview(self.scrubberView)
    }

    @objc
    private func playButtonClicked() {
        self.onPlayButtonClick?()
    }

    @objc
    private func didScrub(_ recognizer: UIGestureRecognizer) {
        var x = recognizer.location(in: self.scrubberView).x
        let width = self.scrubberView.bounds.width
        x.clamp(0, width)

        var ratio: Double = 0
        if width > 0 {
            ratio = x / width
        }
        
        self.onScrub?(ratio)
    }
}

// MARK: - ThemeUpdatable

extension VoiceMessageContentView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.playButton.tintColor = theme.palette.voiceMessagePlayButton
        self.waitingIndicatorView.color = theme.palette.voiceMessagePlayButton
    }
}

// MARK: - MessageContentViewProtocol

extension VoiceMessageContentView: MessageContentViewProtocol {
    var shouldAddBorder: Bool {
        return false
    }

    var shouldAddInfoViewPad: Bool {
        return false
    }

    func currentContentWidth(constrainedBy width: CGFloat, infoViewArea: CGSize) -> CGFloat {
        return width * 0.66
    }

    func reset() {
        self.onPlayButtonClick = nil

        self.waitingIndicatorView.startAnimating()
        self.playButton.isEnabled = false
        self.playButton.setImage(UIImage(), for: .normal)

        self.progressView.setProgress(0.0, animated: false)
        self.timeLabel.attributedText = nil
    }

    func updateInfoViewFrame(_ frame: CGRect) {
        self.infoViewFrame = frame
    }

    func setLongPressHandler(_ handler: @escaping () -> Void) -> Bool { false }
}

extension CGFloat {
    mutating func clamp(_ lower: CGFloat, _ upper: CGFloat) {
        self = Swift.min(self, upper)
        self = Swift.max(self, lower)
    }
}
