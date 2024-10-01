import UIKit

final class FullImageViewController: UIViewController {
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.delegate = self
        return scrollView
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var closeButton: UIView = {
        let view = UIView()

        let image = ThemeProvider.current.imageSet.fullImageCloseButton.withRenderingMode(.alwaysTemplate)
        let imageView = UIImageView(image: image)
        imageView.tintColor = ThemeProvider.current.palette.fullImageCloseButtonTintColor

        let backgroundView = UIView()
        backgroundView.make(.size, .equal, [32, 32])
        backgroundView.layer.cornerRadius = 16
        backgroundView.layer.masksToBounds = true
        backgroundView.backgroundColor = ThemeProvider.current.palette.fullImageCloseButtonBackgroundColor
        backgroundView.addSubview(imageView)
        view.addSubview(backgroundView)

        imageView.make(.center, .equalToSuperview)
        backgroundView.make(.center, .equalToSuperview)

        view.make(.size, .equal, [44, 44])

        view.addTapHandler { [weak self] in
            self?.dismiss(animated: true)
        }

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupSubviews()
    }

    func set(image: UIImage) {
        self.imageView.image = image
    }

    // MARK: - Private

    private func setupSubviews() {
        guard let view = self.view else {
            return
        }

        view.backgroundColor = .black

        view.addSubview(self.scrollView)
        view.addSubview(self.closeButton)
        self.scrollView.addSubview(self.imageView)

        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor).isActive = true
        self.imageView.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor).isActive = true
        self.imageView.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true
        self.imageView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor).isActive = true
        self.imageView.heightAnchor.constraint(equalTo: self.scrollView.heightAnchor).isActive = true
        self.imageView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor).isActive = true

        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        self.closeButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10).isActive = true
        if #available(iOS 11.0, *) {
            self.closeButton.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 0
            ).isActive = true
        } else {
            self.closeButton.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        }
    }
}

extension FullImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
