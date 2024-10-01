import UIKit

final class LocationControlView: UIView, ThemeUpdatable {
    private enum Appearance {
        static let buttonSize = CGSize(width: 44, height: 44)
    }

    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.infoButtonClicked), for: .touchUpInside)
        return button
    }()

    private lazy var positionButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.positionButtonClicked), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(
            arrangedSubviews: [self.infoButton, self.makeSeparatorView(), self.positionButton]
        )
        stackView.axis = .vertical
        return stackView
    }()

    private lazy var effectView = UIVisualEffectView(effect: UIBlurEffect(style: .prominent))

    private var themeProvider: ThemeProvider?

    var onPositionButtonTap: (() -> Void)?
    var onInfoButtonTap: (() -> Void)?

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

    func update(with theme: Theme) {
        self.infoButton.setImage(theme.imageSet.locationInfoButton, for: .normal)
        self.positionButton.setImage(theme.imageSet.locationPositionButton, for: .normal)

        self.infoButton.tintColor = theme.palette.locationControlButton
        self.positionButton.tintColor = theme.palette.locationControlButton

        self.effectView.backgroundColor = theme.palette.locationControlBackground
        self.layer.borderColor = theme.palette.locationControlBorder.cgColor

        for view in self.stackView.arrangedSubviews where !(view is UIButton) {
            view.backgroundColor = theme.palette.locationControlBorder
        }
    }

    // MARK: - Private

    @objc
    private func infoButtonClicked() {
        self.onInfoButtonTap?()
    }

    @objc
    private func positionButtonClicked() {
        self.onPositionButtonTap?()
    }

    private func makeSeparatorView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return view
    }

    private func setupView() {
        let effectView = self.effectView
        self.insertSubview(effectView, at: 0)
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        effectView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        effectView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        effectView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        let stackView = self.stackView
        effectView.contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: effectView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: effectView.trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: effectView.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor).isActive = true

        [self.infoButton, self.positionButton].forEach {
            $0.widthAnchor.constraint(equalToConstant: Appearance.buttonSize.width).isActive = true
            $0.heightAnchor.constraint(equalToConstant: Appearance.buttonSize.height).isActive = true
        }

        self.clipsToBounds = true
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 0.5
    }
}
