import UIKit

final class LoadingIndicatorCollectionViewCell: UICollectionViewCell {
    private static let indicatorSize = CGSize(width: 24, height: 24)

    private lazy var loadingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.hidesWhenStopped = false
        view.startAnimating()
        view.style = .gray
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.loadingIndicatorView.startAnimating()
        self.loadingIndicatorView.alpha = 1.0
    }

    // MARK: - Private

    private func setupView() {
        self.contentView.addSubview(self.loadingIndicatorView)
        self.loadingIndicatorView.make(.size, .equal, [Self.indicatorSize.width, Self.indicatorSize.height])
        self.loadingIndicatorView.make(.center, .equalToSuperview)
    }
}
