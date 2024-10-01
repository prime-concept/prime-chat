import UIKit

final class MessageReplyView: UIView {
    private enum Appearance {
        static let nameInsets = UIEdgeInsets(top: 12, left: 10, bottom: 2, right: 10)
        static let nameHeight: CGFloat = 14

        static let contentHeight: CGFloat = 14

        static let lineSize = CGSize(width: 2, height: 33)
        static let lineTopInset: CGFloat = 12
        static let lineLeftInset: CGFloat = 15
    }

    private lazy var nameLabel = UILabel()

    private lazy var contentLabel = UILabel()

    private lazy var lineView = UIView()

    private var themeProvider: ThemeProvider?

    override init(frame: CGRect) {
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

        self.lineView.frame = CGRect(
            origin: CGPoint(x: Appearance.lineLeftInset, y: Appearance.lineTopInset),
            size: Appearance.lineSize
        )

        self.nameLabel.frame = CGRect(
            x: self.lineView.frame.maxX + Appearance.nameInsets.left,
            y: Appearance.nameInsets.top,
            width: self.bounds.width - Appearance.nameInsets.right
            - self.lineView.frame.maxX
            - Appearance.nameInsets.left,
            height: Appearance.nameHeight
        )

        self.contentLabel.frame = CGRect(
            x: self.lineView.frame.maxX + Appearance.nameInsets.left,
            y: self.nameLabel.frame.maxY + Appearance.nameInsets.bottom,
            width: self.bounds.width - Appearance.nameInsets.right
            - self.lineView.frame.maxX
            - Appearance.nameInsets.left,
            height: Appearance.contentHeight
        )
    }

    override var intrinsicContentSize: CGSize {
        let lineHeight = Appearance.lineTopInset + Appearance.lineSize.height
        let textHeight = Appearance.nameInsets.top + Appearance.nameHeight +
        Appearance.nameInsets.bottom + Appearance.contentHeight
        let height = max(lineHeight, textHeight)

        let textWidth = max(self.nameWidth, self.contentWidth)
        let width = Appearance.lineLeftInset +
        Appearance.lineSize.width +
        Appearance.nameInsets.left +
        textWidth +
        Appearance.nameInsets.right
        return CGSize(width: width, height: height)
    }

    // MARK: - Public

    func configure(with replyMeta: MessageReplyModelMeta, isIncome: Bool) {
        guard let theme = self.themeProvider?.current else {
            return
        }

        self.nameLabel.set(text: replyMeta.senderName, with: theme.fontProvider.messageReplyName)

        self.contentLabel.set(text: replyMeta.content, with: theme.fontProvider.messageReplyText)
        self.contentLabel.lineBreakMode = .byTruncatingTail

        self.lineView.backgroundColor = isIncome
        ? theme.palette.replyIncomeLineBackground
        : theme.palette.replyOutcomeLineBackground
        self.nameLabel.textColor = isIncome
        ? theme.palette.replyIncomeNameText
        : theme.palette.replyOutcomeNameText
        self.contentLabel.textColor = isIncome
            ? theme.palette.replyIncomeContentText
            : theme.palette.replyOutcomeContentText
    }

    // MARK: - Private

    private func setupView() {
        self.addSubview(self.lineView)
        self.addSubview(self.nameLabel)
        self.addSubview(self.contentLabel)
    }

    private var nameWidth: CGFloat {
        guard let theme = self.themeProvider?.current else {
            return 0
        }

        let width = self.nameLabel.text?.width(
            constrainedBy: Appearance.nameHeight,
            maxWidth: .infinity,
            fontDescriptor: theme.fontProvider.messageReplyName
        ) ?? 0

        return width
    }

    private var contentWidth: CGFloat {
        guard let theme = self.themeProvider?.current else {
            return 0
        }

        let width = self.contentLabel.text?.width(
            constrainedBy: Appearance.contentHeight,
            maxWidth: .infinity,
            fontDescriptor: theme.fontProvider.messageReplyText
        ) ?? 0

        return width
    }
}

// MARK: - ThemeUpdatable

extension MessageReplyView: ThemeUpdatable {
    func update(with theme: Theme) {
    }
}
