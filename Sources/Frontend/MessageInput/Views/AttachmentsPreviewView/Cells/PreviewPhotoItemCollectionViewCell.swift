import UIKit
import Photos

final class PreviewPhotoItemCollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier: String { String(describing: self) }

    private enum Appearance {
        static let imageViewRadius: CGFloat = 8
        static let removeButtonSize = CGSize(width: 24, height: 24)
        static let removeButtonTop: CGFloat = 4
        static let removeButtonRight: CGFloat = 4
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
        self.imageView.image = model.previewImage
    }

    // MARK: - Private API

    private func setupView() {
        let imageView = self.imageView
        let contentView = self.contentView

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        let removeButton = self.removeButton
        contentView.addSubview(removeButton)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.topAnchor
            .constraint(equalTo: contentView.topAnchor, constant: Appearance.removeButtonTop).isActive = true
        removeButton.trailingAnchor
            .constraint(equalTo: contentView.trailingAnchor, constant: -Appearance.removeButtonRight).isActive = true
        removeButton.widthAnchor.constraint(equalToConstant: Appearance.removeButtonSize.width).isActive = true
        removeButton.heightAnchor.constraint(equalToConstant: Appearance.removeButtonSize.height).isActive = true
    }

    @objc
    private func removeTapped() {
        self.onRemoveTap?()
    }
}

// MARK: - ThemeUpdatable

extension PreviewPhotoItemCollectionViewCell: ThemeUpdatable {
    func update(with theme: Theme) {
        self.contentView.backgroundColor = theme.palette.imagePickerBackground
        self.backgroundColor = theme.palette.imagePickerBackground

        self.imageView.backgroundColor = theme.palette.imagePickerPreviewBackground
    }
}
