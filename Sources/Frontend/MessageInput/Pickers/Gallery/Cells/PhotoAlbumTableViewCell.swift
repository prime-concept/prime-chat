import UIKit
import Photos

struct PhotoAlbum {
    let thumbnailAsset: PHAsset?
    let title: String
    let count: Int
}

final class PhotoAlbumTableViewCell: UITableViewCell {
    static var reuseIdentifier: String { String(describing: self) }
    static let height: CGFloat = Appearance.height

    private enum Appearance {
        static let height: CGFloat = 55

        static let thumbnailSize = CGSize(width: 36, height: 36)
        static let thumbnailImageSize = CGSize(width: 72, height: 72)
        static let thumbnailRadius: CGFloat = 5

        static let titleFont = ThemeProvider.current.fontProvider.pickerAlbumTitle
        static let countFont = ThemeProvider.current.fontProvider.pickerAlbumCount
    }

    private lazy var thumbnailImage: UIImageView = {
        let image = UIImageView()
        image.layer.masksToBounds = true
        image.layer.cornerRadius = Appearance.thumbnailRadius
        return image
    }()

    private lazy var albumTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.titleFont.font
        return label
    }()

    private lazy var countLabel: UILabel = {
        let label = UILabel()
        label.font = Appearance.countFont.font
        return label
    }()

    private var themeProvider: ThemeProvider?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setupView()
        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    func configure(with model: PhotoAlbum) {
        self.albumTitleLabel.text = model.title
        self.countLabel.text = "\(model.count)"

        model.thumbnailAsset?.getAssetAsImage(size: Appearance.thumbnailImageSize) { [weak self] image in
            self?.thumbnailImage.image = image
        }
    }

    // MARK: - Private API

    private func setupView() {
        let thumbnail = self.thumbnailImage
        let titleLabel = self.albumTitleLabel
        let countLabel = self.countLabel

        [thumbnail, titleLabel, countLabel].forEach(self.contentView.addSubview)

        let thumbnailSize = Appearance.thumbnailSize
        thumbnail.translatesAutoresizingMaskIntoConstraints = false
        thumbnail.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15).isActive = true
        thumbnail.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        thumbnail.widthAnchor.constraint(equalToConstant: thumbnailSize.width).isActive = true
        thumbnail.heightAnchor.constraint(equalToConstant: thumbnailSize.height).isActive = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: 12).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: countLabel.leadingAnchor, constant: -12).isActive = true

        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -15).isActive = true
        countLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor).isActive = true
        countLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }
}

extension PhotoAlbumTableViewCell: ThemeUpdatable {
    func update(with theme: Theme) {
        self.contentView.backgroundColor = theme.palette.imagePickerBackground
        self.backgroundColor = theme.palette.imagePickerBackground

        self.thumbnailImage.backgroundColor = theme.palette.imagePickerPreviewBackground
        self.albumTitleLabel.textColor = theme.palette.imagePickerAlbumTitle
        self.countLabel.textColor = theme.palette.imagePickerAlbumCount
    }
}
