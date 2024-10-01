import UIKit

final class VideoInfoView: UIView {
    private enum Appearance {
        static let height: CGFloat = 13.0
        static let playImageSize = CGSize(width: 6, height: 8)
        static let playImageRightMargin: CGFloat = ThemeProvider.current.layoutProvider.videoInfoPlayImageRightMargin

        static let timeFont = ThemeProvider.current.fontProvider.videoInfoTime
        static let infoViewMarginInsets = UIEdgeInsets(top: 2, left: 5, bottom: 2, right: 5)
    }

    private let timeLabel = UILabel()
    private let playImageView = UIImageView()

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

        self.playImageView.frame = CGRect(
            x: Appearance.infoViewMarginInsets.left,
            y: (self.frame.height - Appearance.playImageSize.height) / 2,
            width: Appearance.playImageSize.width,
            height: Appearance.playImageSize.height
        )

        self.timeLabel.frame = CGRect(
            x: self.playImageView.frame.maxX + Appearance.playImageRightMargin,
            y: Appearance.infoViewMarginInsets.top,
            width: self.timeLabel.bounds.width,
            height: Appearance.height
        )

        self.layer.cornerRadius = self.bounds.size.height / 2
    }

    func reset() {
        self.timeLabel.text = nil
    }

    func update(with timeString: String?) {
        self.timeLabel.set(text: timeString, with: Appearance.timeFont)
        self.timeLabel.sizeToFit()
    }

    static func size(for timeString: String?) -> CGSize {
        let timeSize = NSAttributedString(
            string: timeString ?? "",
            attributes: [.font: Appearance.timeFont.font]
        ).size()
        return CGSize(
            width: timeSize.width.rounded(.up)
            + Appearance.playImageSize.width + (timeString == nil ? 0 : Appearance.playImageRightMargin)
            + Appearance.infoViewMarginInsets.left
            + Appearance.infoViewMarginInsets.right,
            height: Appearance.height + Appearance.infoViewMarginInsets.top + Appearance.infoViewMarginInsets.bottom
        )
    }

    // MARK: - Private

    private func setupView() {
        self.addSubview(self.timeLabel)

        let playImageView = self.playImageView
        playImageView.contentMode = .scaleAspectFit
        self.addSubview(playImageView)
    }
}

// MARK: - ThemeUpdatable

extension VideoInfoView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.playImageView.image = theme.imageSet.videoMessageInfoPlay.withRenderingMode(.alwaysTemplate)
        self.timeLabel.textColor = theme.palette.videoInfoMain
        self.playImageView.tintColor = theme.palette.videoInfoMain
        self.backgroundColor = theme.palette.videoInfoBackground
    }
}
