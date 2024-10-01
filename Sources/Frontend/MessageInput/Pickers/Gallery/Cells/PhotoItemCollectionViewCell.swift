import UIKit
import Photos

struct PhotoViewModel {
    let asset: PHAsset
}

final class PhotoItemCollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier: String { String(describing: self) }
    static let height: CGFloat = Appearance.height

    private enum Appearance {
        static let imageSize = CGSize(width: 200, height: 200)
        static let markIconSize = CGSize(width: 28, height: 28)
        static let height: CGFloat = 124
    }

    override var isSelected: Bool {
        didSet {
            self.overlayView.isHidden = !self.isSelected
            self.checkImageView.isHidden = !self.isSelected
        }
    }

    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleToFill
        return image
    }()

    private lazy var checkImageView: PhotoCheckMarkView = {
        let image = PhotoCheckMarkView()
        image.isHidden = true
        return image
    }()

    private lazy var overlayView: UIView = {
        let view = UIView()
        view.isHidden = true
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

    override func layoutSubviews() {
        super.layoutSubviews()

        self.overlayView.frame = self.imageView.frame
    }

    // MARK: - Public API

    func configure(with model: PhotoViewModel) {
        model.asset.getAssetAsImage(size: Appearance.imageSize) { [weak self] image in
            self?.imageView.image = image
        }
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

        contentView.addSubview(self.overlayView)

        let checkImageView = self.checkImageView
        contentView.addSubview(checkImageView)
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        checkImageView.widthAnchor.constraint(equalToConstant: Appearance.markIconSize.width).isActive = true
        checkImageView.heightAnchor.constraint(equalToConstant: Appearance.markIconSize.height).isActive = true
    }
}

extension PhotoItemCollectionViewCell: ThemeUpdatable {
    func update(with theme: Theme) {
        self.contentView.backgroundColor = theme.palette.imagePickerBackground
        self.backgroundColor = theme.palette.imagePickerBackground

        self.overlayView.backgroundColor = theme.palette.imagePickerSelectionOverlay
        self.imageView.backgroundColor = theme.palette.imagePickerPreviewBackground
    }
}
