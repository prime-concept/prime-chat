import UIKit

final class PhotoCheckMarkView: UIView {
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 30, height: 28)
    }

    var image: UIImage? {
        didSet {
            self.imageView.image = self.image
        }
    }

    private lazy var imageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        return image
    }()

    private lazy var backgroundImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        return image
    }()

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
        self.addSubview(self.backgroundImageView)
        self.addSubview(self.imageView)

        self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundImageView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.backgroundImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.backgroundImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.backgroundImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 6).isActive = true
        self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -4).isActive = true
    }
}

extension PhotoCheckMarkView: ThemeUpdatable {
    func update(with theme: Theme) {
        let backgroundImage = theme.imageSet.imagePickerCheckMarkBackground.withRenderingMode(.alwaysTemplate)
        self.backgroundImageView.image = backgroundImage
        self.imageView.image = theme.imageSet.imagePickerCheckMark.withRenderingMode(.alwaysTemplate)

        self.backgroundImageView.tintColor = theme.palette.imagePickerCheckMarkBackground
        self.imageView.tintColor = theme.palette.imagePickerCheckMark
    }
}
