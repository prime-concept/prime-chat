import UIKit

final class MessageInfoView: UIView {
    private enum Appearance {
        static let height: CGFloat = 13.0
        static let messengerImageSize = CGSize(width: 11, height: 11)
        static let messengerImageRight: CGFloat = 2

        static let statusImageSize = CGSize(width: 13, height: 8)
        static let statusImageLeftMargin: CGFloat = 2.0

        static let timeFont = ThemeProvider.current.fontProvider.messageInfoTime
        static let infoViewMarginInsets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 4)
    }

    private let timeLabel = UILabel()
    private let statusImageView = UIImageView()
    private let infoViewPadView = UIView()
    private lazy var messengerIconImageView: UIImageView =  {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var themeProvider: ThemeProvider?

    private var meta: MessageContainerModelMeta?

    var useBackgroundPad = false {
        didSet {
            self.infoViewPadView.isHidden = !self.useBackgroundPad
            self.updateTimeAndStatusColors(isOutcome: self.meta?.author == .me)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        self.messengerIconImageView.isHidden = true
        self.timeLabel.attributedText = nil
        self.statusImageView.image = nil
        self.useBackgroundPad = false
    }

    func update(with meta: MessageContainerModelMeta) {
        guard let imageSet = self.themeProvider?.current.imageSet else {
            return
        }

        let status: UIImage? = {
            switch meta.status {
            case .seen:
                return imageSet.statusSentReadMessage
            case .unseen:
                return imageSet.statusSentUnreadMessage
            case .sending:
                return imageSet.statusSendingMessage
            case .notSent:
                return imageSet.statusSendingMessage
            case .failed:
                return nil
            }
        }()

        let isStatusHidden = meta.author != .me || meta.status == .failed

        self.messengerIconImageView.image = self.messengerImage(for: meta)
        self.messengerIconImageView.isHidden = self.messengerIconImageView.image == nil

        self.timeLabel.set(text: meta.time, with: Appearance.timeFont)
        self.timeLabel.sizeToFit()

        self.statusImageView.image = status?.withRenderingMode(.alwaysTemplate)
        self.statusImageView.isHidden = isStatusHidden

        self.updateTimeAndStatusColors(isOutcome: meta.author == .me)

        self.meta = meta
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var startX = Appearance.infoViewMarginInsets.left
        let timeLabelTop = Appearance.infoViewMarginInsets.top
        + (self.timeLabel.frame.height - Appearance.statusImageSize.height) / 2

        if self.messengerIconImageView.image != nil {
            self.messengerIconImageView.frame = CGRect(
                x: startX,
                y: timeLabelTop,
                width: Appearance.messengerImageSize.width,
                height: Appearance.messengerImageSize.height
            )

            startX += Appearance.messengerImageSize.width + Appearance.messengerImageRight
        }

        self.timeLabel.frame = CGRect(
            x: startX,
            y: Appearance.infoViewMarginInsets.top,
            width: self.timeLabel.bounds.width,
            height: Appearance.height
        )
        self.statusImageView.frame = CGRect(
            x: self.timeLabel.frame.maxX + Appearance.statusImageLeftMargin,
            y: timeLabelTop,
            width: Appearance.statusImageSize.width,
            height: Appearance.statusImageSize.height
        )

        self.infoViewPadView.frame = self.bounds
        self.infoViewPadView.layer.cornerRadius = self.bounds.size.height / 2
    }

    static func size(for meta: MessageContainerModelMeta) -> CGSize {
        let timeSize = NSAttributedString(
            string: meta.time,
            attributes: [.font: Appearance.timeFont.font]
        ).size()

        let isStatusHidden = meta.author != .me || meta.status == .failed

        var width = timeSize.width.rounded(.up)
        + (isStatusHidden ?  0 : (Appearance.statusImageSize.width + Appearance.statusImageLeftMargin))
        + Appearance.infoViewMarginInsets.left
        + Appearance.infoViewMarginInsets.right
        if meta.messenger != .unknown, meta.messenger != .chat, meta.author == .me {
            width += (Appearance.messengerImageSize.width + Appearance.messengerImageRight)
        }

        width = min(UIScreen.main.bounds.width, width)

        return CGSize(
            width: width,
            height: Appearance.height + Appearance.infoViewMarginInsets.top + Appearance.infoViewMarginInsets.bottom
        )
    }

    func messengerImage(for meta: MessageContainerModelMeta) -> UIImage? {
        guard meta.author == .me,
              let imageSet = self.themeProvider?.current.imageSet else {
            return nil
        }

        switch meta.messenger {
        case .sms:
            return imageSet.otherMessengerSMS
        case .email:
            return imageSet.otherMessengerEmail
        case .telegram:
            return imageSet.otherMessengerTelegram
        case .whatsapp:
            return imageSet.otherMessengerWhatsapp
        default:
            return nil
        }
    }

    // MARK: - Private

    private func updateTimeAndStatusColors(isOutcome: Bool) {
        (self.themeProvider?.current.palette).flatMap {
            if self.useBackgroundPad {
                self.timeLabel.textColor = $0.bubbleInfoPadText
                self.statusImageView.tintColor = $0.bubbleInfoPadText
            } else {
                self.timeLabel.textColor = isOutcome ? $0.bubbleOutcomeInfoTime : $0.bubbleIncomeInfoTime
                self.statusImageView.tintColor = $0.bubbleInfoStatusIcon
            }
        }
    }

    private func setupView() {
        self.addSubview(self.infoViewPadView)
        self.infoViewPadView.isHidden = true
        self.infoViewPadView.clipsToBounds = true

        self.addSubview(self.timeLabel)
        self.addSubview(self.messengerIconImageView)

        let statusImageView = self.statusImageView
        statusImageView.contentMode = .scaleAspectFit
        self.addSubview(statusImageView)
    }
}

// MARK: - ThemeUpdatable

extension MessageInfoView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.infoViewPadView.backgroundColor = theme.palette.bubbleInfoPadBackground
    }
}
