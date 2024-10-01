import UIKit

final class TimeSeparatorCollectionViewCell: UICollectionViewCell {
    private lazy var separatorView = TimeSeparatorView()

    var text: String = "" {
        didSet {
            self.separatorView.text = self.text
        }
    }

    static let height: CGFloat = TimeSeparatorView.height

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let separator = self.separatorView
        separator.bounds = self.contentView.bounds
        separator.center = self.contentView.center
    }

    // MARK: - Private

    private func setupView() {
        self.contentView.addSubview(self.separatorView)
    }
}
