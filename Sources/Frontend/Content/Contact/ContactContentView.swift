import UIKit

final class ContactContentView: HighlightableView {
    private enum Appearance {
        static let titleLeftInset: CGFloat = 12
        static let titleRightInset: CGFloat = 16
        static let iconSize = CGSize(width: 36, height: 36)
        static let iconLeftInset: CGFloat = 9
        static let phoneLabelTopInset: CGFloat = 2
        static let titleTopInset: CGFloat = -2
    }
    
    static let height: CGFloat = 54

    var guid: String?

    private var rightInfoWidth: CGFloat = 0
    private var isLoading = false

    private lazy var iconImageView = UIImageView()
    private lazy var iconBackgroundView = UIView()

    private lazy var titleLabel = UILabel()

    private lazy var phoneLabel = UILabel()

    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.gestureRecognized(_:)))
        return recognizer
    }()

    private var themeProvider: ThemeProvider?

    var onTap: (() -> Void)?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.themeProvider = ThemeProvider(themeUpdatable: self)

        self.setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let size = self.bounds.size

        self.iconBackgroundView.frame = CGRect(
            x: Appearance.iconLeftInset,
            y: size.height / 2 - Appearance.iconSize.height / 2,
            width: Appearance.iconSize.width,
            height: Appearance.iconSize.height
        )
        self.iconBackgroundView.clipsToBounds = true
        self.iconBackgroundView.layer.cornerRadius = Appearance.iconSize.height / 2

        self.iconImageView.frame = self.iconBackgroundView.bounds

        let widthForText = size.width
        - (self.iconBackgroundView.frame.maxX + Appearance.titleLeftInset)
        - Appearance.titleRightInset
        if self.isLoading {
            self.titleLabel.frame = CGRect(
                x: self.iconBackgroundView.frame.maxX + Appearance.titleLeftInset,
                y: size.height / 2 - self.titleLabel.bounds.height / 2 - Appearance.titleTopInset,
                width: widthForText - self.rightInfoWidth,
                height: self.titleLabel.bounds.height
            )
        } else {
            let topOffset = (size.height - self.titleLabel.bounds.height - self.phoneLabel.bounds.height) / 2
            + Appearance.titleTopInset
            self.titleLabel.frame = CGRect(
                x: self.iconBackgroundView.frame.maxX + Appearance.titleLeftInset,
                y: topOffset,
                width: widthForText,
                height: self.titleLabel.bounds.height
            )

            self.phoneLabel.frame = CGRect(
                x: self.titleLabel.frame.minX,
                y: self.titleLabel.frame.maxY + Appearance.phoneLabelTopInset,
                width: widthForText - self.rightInfoWidth,
                height: self.phoneLabel.bounds.height
            )
        }
    }

    func update(model: Model?, meta: MessageContainerModelMeta) {
        guard let palette = self.themeProvider?.current.palette,
              let fontProvider = self.themeProvider?.current.fontProvider else {
            return
        }

        let title = model?.name ?? "loading".localized
        if let model = model {
            self.phoneLabel.set(text: model.phone, with: fontProvider.contactPhone)
            self.phoneLabel.textColor = meta.author == .me ? palette.contactOutcomePhone : palette.contactIncomePhone

            self.phoneLabel.isHidden = false
            self.isLoading = false
        } else {
            self.phoneLabel.isHidden = true
            self.isLoading = true
        }

        self.titleLabel.set(text: title, with: fontProvider.contactTitle)
        self.titleLabel.textColor = meta.author == .me ? palette.contactOutcomeTitle : palette.contactIncomeTitle
        self.titleLabel.lineBreakMode = .byTruncatingTail

        self.iconBackgroundView.backgroundColor = meta.author == .me
        ? palette.contactIconOutcomeBackground
        : palette.contactIconIncomeBackground
        self.titleLabel.sizeToFit()
        self.phoneLabel.sizeToFit()

        self.setNeedsLayout()
    }

    // MARK: - Private

    private func setupSubviews() {
        self.addSubview(self.iconBackgroundView)
        self.iconBackgroundView.addSubview(self.iconImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.phoneLabel)

        self.addGestureRecognizer(self.tapRecognizer)
    }

    @objc
    private func gestureRecognized(_ recognizer: UITapGestureRecognizer) {
        if self.isLoading {
            return
        }

        self.onTap?()
    }

    // MARK: - View model

    struct Model {
        let name: String
        let phone: String
    }
}

// MARK: - MessageContentViewProtocol

extension ContactContentView: MessageContentViewProtocol {
    var openContent: ((@escaping MessageContentOpeningCompletion) -> Void)? {
        nil
    }

    var shouldAddBorder: Bool {
        return false
    }

    var shouldAddInfoViewPad: Bool {
        return false
    }

    func currentContentWidth(constrainedBy width: CGFloat, infoViewArea: CGSize) -> CGFloat {
        return width
    }

    func reset() {
        self.titleLabel.text = nil
    }

    func updateInfoViewFrame(_ frame: CGRect) {
        self.rightInfoWidth = frame.size.width
        self.setNeedsLayout()
    }
    
    func setLongPressHandler(_ handler: @escaping () -> Void) -> Bool { false }
}

// MARK: - ThemeUpdatable

extension ContactContentView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.iconImageView.image = theme.imageSet.contactBubbleIcon.withRenderingMode(.alwaysTemplate)
        self.iconImageView.tintColor = theme.palette.contactIcon
    }
}
