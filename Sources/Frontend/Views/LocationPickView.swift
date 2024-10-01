import UIKit

final class LocationPickView: UIView, ThemeUpdatable {
    private enum Appearance {
        static let pinIconSize = CGSize(width: 44, height: 44)
        static let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        static let labelsLeftInset: CGFloat = 4
    }

    private lazy var pinIconView = UIImageView()

    private lazy var titleLabel = UILabel()

    private lazy var subtitleLabel = UILabel()

    private lazy var tapRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.gestureRecognized(_:)))
        recognizer.minimumPressDuration = 0.0
        return recognizer
    }()

    private var themeProvider: ThemeProvider?

    override var intrinsicContentSize: CGSize {
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: Appearance.insets.top + Appearance.insets.bottom + Appearance.pinIconSize.height
        )
    }

    var onTap: (() -> Void)?

    var title: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.set(text: newValue, with: ThemeProvider.current.fontProvider.locationPickTitle)
        }
    }

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

        self.layer.shadowPath = UIBezierPath(
            roundedRect: self.bounds,
            cornerRadius: self.layer.cornerRadius
        ).cgPath
    }

    func update(locationName: String) {
        self.subtitleLabel.set(text: locationName, with: ThemeProvider.current.fontProvider.locationPickSubtitle)
        self.subtitleLabel.lineBreakMode = .byTruncatingTail
    }

    func reset() {
        self.subtitleLabel.set(text: "loading".localized, with: ThemeProvider.current.fontProvider.locationPickSubtitle)
    }

    func update(with theme: Theme) {
        self.pinIconView.image = theme.imageSet.locationPin
        self.titleLabel.textColor = theme.palette.locationPickTitle
        self.subtitleLabel.textColor = theme.palette.locationPickSubtitle
        self.backgroundColor = theme.palette.locationPickBackground
    }

    // MARK: - Private

    @objc
    private func gestureRecognized(_ recognizer: UILongPressGestureRecognizer) {
        self.pch_defaultTapGestureHandler(recognizer) { [weak self] in self?.onTap?() }
    }

    private func setupView() {
        let pinIconView = self.pinIconView

        self.addSubview(pinIconView)
        pinIconView.translatesAutoresizingMaskIntoConstraints = false
        pinIconView.leadingAnchor
            .constraint(equalTo: self.leadingAnchor, constant: Appearance.insets.left)
            .isActive = true
        pinIconView.widthAnchor.constraint(equalToConstant: Appearance.pinIconSize.width).isActive = true
        pinIconView.heightAnchor.constraint(equalToConstant: Appearance.pinIconSize.height).isActive = true
        pinIconView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        let labelsStackView = UIStackView(arrangedSubviews: [self.titleLabel, self.subtitleLabel])
        labelsStackView.axis = .vertical

        self.addSubview(labelsStackView)
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.leadingAnchor
            .constraint(equalTo: pinIconView.trailingAnchor, constant: Appearance.labelsLeftInset)
            .isActive = true
        labelsStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        labelsStackView.trailingAnchor
            .constraint(equalTo: self.trailingAnchor, constant: -Appearance.insets.right)
            .isActive = true
        labelsStackView.spacing = 4

        self.layer.cornerRadius = 10
        self.clipsToBounds = true

        self.layer.shadowColor = UIColor.black.withAlphaComponent(0.15).cgColor
        self.layer.shadowOpacity = 1.0
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 10
        self.layer.masksToBounds = false

        self.addGestureRecognizer(self.tapRecognizer)
    }
}
