import UIKit

final class AttachmentBadgeView: UIView {
    override var intrinsicContentSize: CGSize {
        return self.size
    }

    private let size: CGSize
    private var themeProvider: ThemeProvider?

    var badgeValue: Int = 0 {
        didSet {
            self.label.text = "\(self.badgeValue)"
        }
    }

    var badgeFont: UIFont = ThemeProvider.current.fontProvider.badge.font {
        didSet {
            self.label.font = self.badgeFont
        }
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = self.badgeFont
        return label
    }()

    init(size: CGSize) {
        self.size = size
        super.init(frame: .zero)
        self.setupView()
        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.invalidateIntrinsicContentSize()

        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.cornerRadius = self.size.width / 2
    }

    // MARK: - Private API

    private func setupView() {
        self.addSubview(self.label)
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
}

extension AttachmentBadgeView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.backgroundColor = theme.palette.attachmentBadgeBackground
        self.label.textColor = theme.palette.attachmentBadgeText
        self.layer.borderColor = theme.palette.attachmentBadgeBorder.cgColor
    }
}
