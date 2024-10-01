import UIKit

final class ReplyPreviewView: UIView {
    private lazy var replyIconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var shadowView = UIView()

    private lazy var nameLabel = UILabel()

    private lazy var replyLabel = UILabel()

    private lazy var closeButton: UIButton = {
        let view = UIButton(type: .system)
        view.addTarget(self, action: #selector(self.closeButtonTapped), for: .touchUpInside)
        return view
    }()

    var onCloseTap: (() -> Void)?

    private var themeProvider: ThemeProvider?

    override init(frame: CGRect) {
        super.init(frame: .zero)

        self.setupView()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    func update(sender: String, reply: String) {
        self.nameLabel.set(text: sender, with: ThemeProvider.current.fontProvider.replyName)

        self.replyLabel.set(text: reply, with: ThemeProvider.current.fontProvider.replyText)
        self.replyLabel.lineBreakMode = .byTruncatingTail
    }

    // MARK: - Private

    @objc
    private func closeButtonTapped() {
        self.onCloseTap?()
    }

    private func setupView() {
        let shadowView = self.shadowView
        self.addSubview(shadowView)

        self.nameLabel.textColor = ThemeProvider.current.palette.replyPreviewNameText

        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        shadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        shadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        shadowView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true

        let replyIconView = self.replyIconView
        self.addSubview(replyIconView)

        replyIconView.translatesAutoresizingMaskIntoConstraints = false
        replyIconView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        replyIconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15).isActive = true
        replyIconView.widthAnchor.constraint(equalToConstant: 15).isActive = true
        replyIconView.heightAnchor.constraint(equalToConstant: 15).isActive = true

        let labelsStackView = UIStackView(arrangedSubviews: [self.nameLabel, self.replyLabel])
        labelsStackView.axis = .vertical
        labelsStackView.spacing = 1
        self.addSubview(labelsStackView)

        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        labelsStackView.leadingAnchor.constraint(equalTo: replyIconView.trailingAnchor, constant: 15).isActive = true

        let closeButton = self.closeButton
        self.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        closeButton.leadingAnchor.constraint(equalTo: labelsStackView.trailingAnchor).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
}

// MARK: - ThemeUpdatable

extension ReplyPreviewView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.replyIconView.image = theme.imageSet.replyIcon.withRenderingMode(.alwaysTemplate)
        self.replyIconView.tintColor = theme.palette.replyPreviewIcon

        self.nameLabel.textColor = theme.palette.replyPreviewNameText
        self.replyLabel.textColor = theme.palette.replyPreviewReplyText

        self.closeButton.tintColor = theme.palette.replyPreviewRemoveButton
        self.closeButton.setImage(theme.imageSet.replyPreviewRemove, for: .normal)

        self.shadowView.backgroundColor = theme.palette.senderBorderShadow
    }
}
