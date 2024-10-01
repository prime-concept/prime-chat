import UIKit

final class DocumentContentView: HighlightableView {
    private enum Appearance {
        static let documentButtonInsets = UIEdgeInsets(top: 9, left: 9, bottom: 9, right: 12)
        static let circleProgressButtonSize = CGSize(width: 20, height: 20)
        static let documentButtonSize = CGSize(width: 36, height: 36)
        static let documentNameHeight: CGFloat = ThemeProvider.current.fontProvider.documentName.lineHeight ?? 21.0
        static let documentNameRightInset: CGFloat = 8.0
        static let documentNameTopInset: CGFloat = -2
        static let documentSizeHeight: CGFloat = ThemeProvider.current.fontProvider.documentSize.lineHeight ?? 16.0
        static let documentSizeTopInset: CGFloat = 1.0
    }

    static let height: CGFloat = 54

    var guid: String?

    private lazy var documentButton: UIButton = {
        let button = UIButton(type: .system)
        button.contentMode = .center
        button.isUserInteractionEnabled = false
        return button
    }()

    private lazy var documentNameLabel = UILabel()

    private lazy var documentSizeLabel = UILabel()

    private lazy var circleProgressViewContainer = UIView()
    private lazy var circleProgressView = CircleProgressView()

    private var infoViewFrame: CGRect?
    private var themeProvider: ThemeProvider?
    private var lastAnimateAction = false

    var onDocumentButtonClick: (() -> Void)?

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.gestureRecognized(_:)))
        return recognizer
    }()

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

        self.documentButton.frame = CGRect(
            x: Appearance.documentButtonInsets.left,
            y: Appearance.documentButtonInsets.top,
            width: Appearance.documentButtonSize.width,
            height: Appearance.documentButtonSize.height
        )

        self.documentButton.layer.cornerRadius = Appearance.documentButtonSize.width / 2

        self.circleProgressViewContainer.bounds.size = Appearance.documentButtonSize
        self.circleProgressViewContainer.center = self.documentButton.center
        self.circleProgressViewContainer.layer.cornerRadius = Appearance.documentButtonSize.width / 2

        self.circleProgressView.frame.origin = CGPoint(
            x: (Appearance.documentButtonSize.width - Appearance.circleProgressButtonSize.width) / 2,
            y: (Appearance.documentButtonSize.height - Appearance.circleProgressButtonSize.height) / 2
        )
        self.circleProgressView.bounds.size = Appearance.circleProgressButtonSize

        let isNameLabelEmpty = (self.documentNameLabel.text?.isEmpty ?? true) || self.documentNameLabel.isHidden
        let isSizeLabelEmpty = (self.documentSizeLabel.text?.isEmpty ?? true) || self.documentSizeLabel.isHidden

        let nameHeight = isNameLabelEmpty ? 0 : Appearance.documentNameHeight
        let sizeHeight = isSizeLabelEmpty ? 0 : Appearance.documentSizeHeight

        let size = self.bounds.size
        let topOffset = (size.height - nameHeight - sizeHeight) / 2 + Appearance.documentNameTopInset

        if isSizeLabelEmpty {
            self.documentNameLabel.frame = CGRect(
                x: self.documentButton.frame.maxX + Appearance.documentButtonInsets.right,
                y: (size.height - self.documentNameLabel.bounds.height) / 2,
                width: self.bounds.width
                - self.documentButton.frame.maxX
                - Appearance.documentButtonInsets.right
                - Appearance.documentNameRightInset,
                height: Appearance.documentNameHeight
            )
            return
        }

        self.documentNameLabel.frame = CGRect(
            x: self.documentButton.frame.maxX + Appearance.documentButtonInsets.right,
            y: topOffset,
            width: self.bounds.width
            - self.documentButton.frame.maxX
            - Appearance.documentButtonInsets.right
            - Appearance.documentNameRightInset,
            height: Appearance.documentNameHeight
        )

        self.documentSizeLabel.frame = CGRect(
            x: self.documentNameLabel.frame.minX,
            y: self.documentNameLabel.frame.maxY + Appearance.documentSizeTopInset,
            width: (self.infoViewFrame?.minX ?? self.bounds.width)
            - self.documentButton.frame.maxX
            - Appearance.documentButtonInsets.right
            - Appearance.documentNameRightInset,
            height: Appearance.documentSizeHeight
        )
    }

    func update(with model: Model) {
        guard let theme = self.themeProvider?.current else {
            return
        }

        model.progress.flatMap { self.circleProgressView.progress = CGFloat($0) }
        self.documentSizeLabel.set(
            text: formattedSize(from: model),
            with: theme.fontProvider.documentSize

        )

        var isLoaderHidden = true
        if let progress = model.progress, progress < 1 {
            isLoaderHidden = false
        }

        self.circleProgressViewContainer.isHidden = isLoaderHidden
        self.documentButton.isHidden = !isLoaderHidden

        let name: String = {
            if let name = model.name, !name.isEmpty {
                return name
            }
            return "file".localized
        }()

        self.documentNameLabel.set(text: name, with: theme.fontProvider.documentName)
        self.documentNameLabel.lineBreakMode = .byTruncatingTail

        self.documentButton.backgroundColor = model.isIncome
            ? theme.palette.documentButtonIncomeBackground
            : theme.palette.documentButtonOutcomeBackground

        self.documentNameLabel.textColor = model.isIncome
            ? theme.palette.bubbleIncomeText
            : theme.palette.bubbleOutcomeText

        self.documentSizeLabel.textColor = model.isIncome
            ? theme.palette.bubbleIncomeInfoTime
            : theme.palette.bubbleOutcomeInfoTime

        self.circleProgressViewContainer.backgroundColor = model.isIncome
            ? theme.palette.documentIncomeProgressBackground
            : theme.palette.documentOutcomeProgressBackground

        self.circleProgressView.progressColor = model.isIncome
            ? theme.palette.documentIncomeProgress
            : theme.palette.documentOutcomeProgress

        self.circleProgressView.untrackedColor = model.isIncome
            ? theme.palette.documentIncomeProgressUntracked
            : theme.palette.documentOutcomeProgressUntracked

        self.setNeedsLayout()
    }

    // MARK: - Private

    private func setupSubviews() {
        self.addSubview(self.documentButton)
        self.addSubview(self.documentNameLabel)
        self.addSubview(self.documentSizeLabel)
        self.addSubview(self.circleProgressViewContainer)
        self.circleProgressViewContainer.addSubview(self.circleProgressView)
        self.addGestureRecognizer(self.tapGestureRecognizer)

        self.reset()

        self.circleProgressView.lineWidth = 3
        self.circleProgressView.startLoading()

        self.circleProgressViewContainer.isHidden = false
        self.documentButton.isHidden = true
    }

    private static func bytesToString(bytes: Float) -> String {
        let count: Float = 1024
        if bytes < count {
           return String(format: "%.1f Б", bytes)
                .replacingOccurrences(of: ".0", with: "")
        }
        let exp = Int(log2((bytes)) / log2(count))
        let unit = ["filesize.kilobytes", "filesize.megabytes"].map(\.localized)[exp - 1]
        let number = bytes / pow(count, Float(exp))
        if exp <= 1 || number >= 100 {
            return String(format: "%.0f %@", number, unit)
        } else {
            return String(format: "%.1f %@", number, unit)
                .replacingOccurrences(of: ".0", with: "")
        }
    }

    private func formattedSize(from model: Model) -> String {
        guard let bCount = model.size else {
            return ""
        }

        let current = model.progress

        let count = Float(bCount)
        if let current = current {
            return String(
                format: "%@ / %@",
                Self.bytesToString(bytes: current * count),
                Self.bytesToString(bytes: count)
            )
        }
        return Self.bytesToString(bytes: count)
    }

    @objc
    private func gestureRecognized(_ recognizer: UITapGestureRecognizer) {
        self.onDocumentButtonClick?()
    }

    // MARK: - Model

    struct Model {
        let name: String?
        let url: URL?
        let progress: Float?
        let size: Double?
        let isIncome: Bool
    }
}

// MARK: - ThemeUpdatable

extension DocumentContentView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.documentButton.setImage(
            theme.imageSet.documentBubbleIcon.withRenderingMode(.alwaysTemplate),
            for: .normal
        )

        self.documentButton.tintColor = theme.palette.documentButtonTint
    }
}

// MARK: - MessageContentViewProtocol

extension DocumentContentView: MessageContentViewProtocol {
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
        self.circleProgressView.progress = 0.0
        self.onDocumentButtonClick = nil
    }

    func updateInfoViewFrame(_ frame: CGRect) {
        self.infoViewFrame = frame
    }
    
    func setLongPressHandler(_ handler: @escaping () -> Void) -> Bool { false }
}
