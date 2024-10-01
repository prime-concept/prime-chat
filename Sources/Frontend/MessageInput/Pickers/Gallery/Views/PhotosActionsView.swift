import UIKit

final class PhotosActionsView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 44)
    }

    private enum Appearance {
        static let countLabelSize = CGSize(width: 24, height: 24)
    }

    var count: Int = 0 {
        didSet {
            self.countBadge.isHidden = self.count == 0
            self.countBadge.badgeValue = self.count
            self.sendButton.isEnabled = self.count > 0
        }
    }

    var cancelButtonClicked: (() -> Void)?
    var sendButtonClicked: (() -> Void)?

    private lazy var cancelButton = self.makeButton(with: "cancel".localized)
    private lazy var sendButton = self.makeButton(with: "send".localized)

    private lazy var countBadge: AttachmentBadgeView = {
        let label = AttachmentBadgeView(size: Appearance.countLabelSize)
        label.isHidden = true
        return label
    }()

    private lazy var borderShadowView = UIView()

    private var themeProvider: ThemeProvider?

    init() {
        super.init(frame: .zero)
        self.setupView()
        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private API

    private func setupView() {
        let sendButton = self.sendButton
        let cancelButton = self.cancelButton
        let countBadge = self.countBadge
        let borderShadowView = self.borderShadowView

        sendButton.isEnabled = false
        self.clipsToBounds = false

        self.addSubview(cancelButton)
        self.addSubview(sendButton)
        self.addSubview(countBadge)
        self.addSubview(borderShadowView)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15).isActive = true
        cancelButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15).isActive = true
        sendButton.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        countBadge.translatesAutoresizingMaskIntoConstraints = false
        countBadge.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        countBadge.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -6).isActive = true

        borderShadowView.translatesAutoresizingMaskIntoConstraints = false
        borderShadowView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        borderShadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        borderShadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        borderShadowView.bottomAnchor.constraint(equalTo: self.topAnchor).isActive = true
    }

    private func makeButton(with title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.titleLabel?.font = ThemeProvider.current.fontProvider.pickerActionsButton.font
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(self.onButtonClicked), for: .touchUpInside)
        return button
    }

    @objc
    private func onButtonClicked(_ button: UIButton) {
        if button === self.cancelButton {
            self.cancelButtonClicked?()
        } else if button === self.sendButton {
            self.sendButtonClicked?()
        }
    }
}

extension PhotosActionsView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.backgroundColor = theme.palette.imagePickerButtonsBackground

        [self.cancelButton, self.sendButton].forEach { button in
            button.setTitleColor(theme.palette.imagePickerBottomButtonTint, for: .normal)
            button.setTitleColor(theme.palette.imagePickerBottomButtonDisabledTint, for: .disabled)
        }

        self.borderShadowView.backgroundColor = theme.palette.imagePickerButtonsBorderShadow
    }
}
