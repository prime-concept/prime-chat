import UIKit
import Photos

final class PreviewVideoItemCollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier: String { String(describing: self) }

    private enum Appearance {
        static let imageViewRadius: CGFloat = 8
        static let removeButtonSize = CGSize(width: 24, height: 24)
        static let removeButtonTop: CGFloat = 4
        static let removeButtonRight: CGFloat = 4
        static let durationLabelFont = ThemeProvider.current.fontProvider.previewVideoDuration
        static let durationLabelInsets = UIEdgeInsets(top: 0, left: 0, bottom: 3.5, right: 4)
        static let bottomGradientHeight: CGFloat = 30
    }

    var onRemoveTap: (() -> Void)?

    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = Appearance.imageViewRadius
        image.clipsToBounds = true
        return image
    }()

    private lazy var removeButton: RemoveBlurButton = {
        let button = RemoveBlurButton()
        button.layer.cornerRadius = Appearance.removeButtonSize.width / 2
        button.addTarget(self, action: #selector(self.removeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var durationLabel: UILabel = {
        let view = UILabel()
        view.font = Appearance.durationLabelFont.font
        return view
    }()

    private var gradientBottomView: GradientBottomView = {
        let view = GradientBottomView()
        view.clipsToBounds = true
        view.shoundRoundBottomCorners = true
        return view
    }()

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

    // MARK: - Public API

    func configure(with model: AttachmentPreview, onRemoveTap: @escaping (() -> Void)) {
        self.onRemoveTap = onRemoveTap
        let timeString: ((Double) -> String) = { duration in
            let time = Int(duration)
            let minutes = Int(time / 60)
            let seconds = Int(time % 60)
            return "\(minutes)" + ":" + (seconds >= 10 ? "\(seconds)" : "0\(seconds)")
        }

        self.imageView.image = model.previewImage
        self.durationLabel.text = timeString(model.duration ?? 0)
    }

    // MARK: - Private API

    private func setupView() {
        let contentView = self.contentView
        contentView.clipsToBounds = true

        let imageView = self.imageView
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        let gradientBottomView = self.gradientBottomView
        contentView.addSubview(gradientBottomView)
        gradientBottomView.translatesAutoresizingMaskIntoConstraints = false
        gradientBottomView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        gradientBottomView.heightAnchor.constraint(equalToConstant: Appearance.bottomGradientHeight).isActive = true
        gradientBottomView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        let removeButton = self.removeButton
        contentView.addSubview(removeButton)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.topAnchor
            .constraint(equalTo: contentView.topAnchor, constant: Appearance.removeButtonTop).isActive = true
        removeButton.trailingAnchor
            .constraint(equalTo: contentView.trailingAnchor, constant: -Appearance.removeButtonRight).isActive = true
        removeButton.widthAnchor.constraint(equalToConstant: Appearance.removeButtonSize.width).isActive = true
        removeButton.heightAnchor.constraint(equalToConstant: Appearance.removeButtonSize.height).isActive = true
        removeButton.layer.cornerRadius = Appearance.removeButtonSize.width / 2

        let durationLabel = self.durationLabel

        contentView.addSubview(durationLabel)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.bottomAnchor
            .constraint(equalTo: contentView.bottomAnchor, constant: -Appearance.durationLabelInsets.bottom)
            .isActive = true
        durationLabel.rightAnchor
            .constraint(equalTo: contentView.rightAnchor, constant: -Appearance.durationLabelInsets.right)
            .isActive = true
    }

    @objc
    private func removeTapped() {
        self.onRemoveTap?()
    }
}

// MARK: - ThemeUpdatable

extension PreviewVideoItemCollectionViewCell: ThemeUpdatable {
    func update(with theme: Theme) {
        self.contentView.backgroundColor = theme.palette.imagePickerBackground
        self.backgroundColor = theme.palette.imagePickerBackground

        self.imageView.backgroundColor = theme.palette.imagePickerPreviewBackground
        self.durationLabel.textColor = theme.palette.imagePickerItemDuration
    }
}
