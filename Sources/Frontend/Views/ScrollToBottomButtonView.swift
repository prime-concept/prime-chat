import UIKit

final class ScrollToBottomButtonView: UIView {
    private enum Appearance {
        static let size = CGSize(width: 44, height: 44)
        static let borderWidth: CGFloat = 0.5
    }

    override var intrinsicContentSize: CGSize {
        return Appearance.size
    }

    private lazy var imageView = UIImageView()

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
        self.layer.cornerRadius = self.frame.width / 2
    }

    // MARK: - Private API

    private func setupView() {
        self.addSubview(self.imageView)
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
}

extension ScrollToBottomButtonView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.backgroundColor = theme.palette.scrollToBottomButtonBackground

        self.imageView.image = theme.imageSet.scrollToBottomButton.withRenderingMode(.alwaysTemplate)
        self.imageView.tintColor = theme.palette.scrollToBottomButtonTint

        self.layer.borderWidth = Appearance.borderWidth
        self.layer.borderColor = theme.palette.scrollToBottomButtonBorder.cgColor
    }
}
