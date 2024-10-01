import UIKit

final class TimeSeparatorView: UIView {
    static let height: CGFloat = 44

    private enum Appearance {
        static let textFont = ThemeProvider.current.fontProvider.timeSeparator

        static let backgroundViewPadding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        static let backgroundViewHeight: CGFloat = 25
        static let backgroundViewCornerRadius: CGFloat = 20
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

    private var themeProvider: ThemeProvider?

    var text: String? {
        didSet {
            if oldValue != self.text {
                self.setTextOnLabel(self.text)
            }
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

    override func layoutSubviews() {
        super.layoutSubviews()

        let label = self.label
        let backgroundView = self.backgroundView

        let backgroundSize = label.bounds.inset(by: Appearance.backgroundViewPadding.negated()).size

        backgroundView.frame = CGRect(
            x: self.bounds.midX - backgroundSize.width / 2,
            y: self.bounds.midY - backgroundSize.height / 2,
            width: backgroundSize.width,
            height: Appearance.backgroundViewHeight
        )

        label.frame = CGRect(
            x: Appearance.backgroundViewPadding.left,
            y: (Appearance.backgroundViewHeight - label.font.pointSize) / 2,
            width: label.bounds.width,
            height: label.bounds.height
        )

        backgroundView.layer.cornerRadius = backgroundView.bounds.height / 2
    }

    // MARK: - Private

    private func setupView() {
        self.backgroundView.clipsToBounds = true

        self.addSubview(self.backgroundView)
        self.backgroundView.contentView.addSubview(self.label)
    }

    private func setTextOnLabel(_ text: String?) {
        self.label.set(text: text, with: Appearance.textFont)
        self.label.sizeToFit()
        self.setNeedsLayout()
    }
}

extension TimeSeparatorView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.label.textColor = theme.palette.timeSeparatorText
        self.backgroundView.backgroundColor = theme.palette.timeSeparatorBackground
    }
}
