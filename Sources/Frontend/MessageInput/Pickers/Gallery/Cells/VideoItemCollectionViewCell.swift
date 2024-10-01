import UIKit
import Photos

final class VideoItemCollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier: String { String(describing: self) }
    static let height: CGFloat = Appearance.height

    private enum Appearance {
        static let imageSize = CGSize(width: 200, height: 200)
        static let markIconSize = CGSize(width: 28, height: 28)
        static let height: CGFloat = 124
        static let durationLabelFont = ThemeProvider.current.fontProvider.pickerVideoDuration
        static let durationLabelInsets = UIEdgeInsets(top: 0, left: 0, bottom: 3.5, right: 4)
        static let bottomGradientHeight: CGFloat = 30
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

    private lazy var durationLabel: UILabel = {
        let view = UILabel()
        view.font = Appearance.durationLabelFont.font
        return view
    }()

    private var themeProvider: ThemeProvider?
    private var gradientBottomView = GradientBottomView()

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
        let timeString: ((Double) -> String) = { duration in
            let time = Int(duration)
            let minutes = Int(time / 60)
            let seconds = Int(time % 60)
            return "\(minutes)" + ":" + (seconds >= 10 ? "\(seconds)" : "0\(seconds)")
        }

        model.asset.getAssetAsVideoImagePreview(size: Appearance.imageSize) { [weak self] image, dutation in
            self?.imageView.image = image
            self?.durationLabel.text = timeString(dutation)
        }
    }

    // MARK: - Private API

    private func setupView() {
        let imageView = self.imageView
        let durationLabel = self.durationLabel
        let contentView = self.contentView
        let gradientBottomView = self.gradientBottomView

        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        contentView.addSubview(gradientBottomView)
        gradientBottomView.translatesAutoresizingMaskIntoConstraints = false
        gradientBottomView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        gradientBottomView.heightAnchor.constraint(equalToConstant: Appearance.bottomGradientHeight).isActive = true
        gradientBottomView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        contentView.addSubview(self.overlayView)

        let checkImageView = self.checkImageView
        contentView.addSubview(checkImageView)
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        checkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        checkImageView.widthAnchor.constraint(equalToConstant: Appearance.markIconSize.width).isActive = true
        checkImageView.heightAnchor.constraint(equalToConstant: Appearance.markIconSize.height).isActive = true

        contentView.addSubview(durationLabel)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.bottomAnchor.constraint(
            equalTo: contentView.bottomAnchor,
            constant: -Appearance.durationLabelInsets.bottom
        ).isActive = true
        durationLabel.rightAnchor.constraint(
            equalTo: contentView.rightAnchor,
            constant: -Appearance.durationLabelInsets.right
        ).isActive = true
    }
}

extension VideoItemCollectionViewCell: ThemeUpdatable {
    func update(with theme: Theme) {
        self.contentView.backgroundColor = theme.palette.imagePickerBackground
        self.backgroundColor = theme.palette.imagePickerBackground

        self.overlayView.backgroundColor = theme.palette.imagePickerSelectionOverlay
        self.imageView.backgroundColor = theme.palette.imagePickerPreviewBackground
        self.durationLabel.textColor = theme.palette.imagePickerItemDuration
    }
}
