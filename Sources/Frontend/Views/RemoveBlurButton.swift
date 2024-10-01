import UIKit

final class RemoveBlurButton: UIButton {
    private enum Appearance {
        static let backgroundColor = UIColor(white: 0.5, alpha: 0.5)
    }

    private var blurEffectView: UIVisualEffectView?
    private var isInited = false
    private var themeProvider: ThemeProvider?

    init() {
        super.init(frame: .zero)
        self.layer.masksToBounds = true

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !self.isInited {
            self.isInited = true

            self.initBlurView()
        }
    }

    private func initBlurView() {
        self.backgroundColor = Appearance.backgroundColor

        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.isUserInteractionEnabled = false

        if let imageView = self.imageView {
            self.insertSubview(blurEffectView, belowSubview: imageView)
        } else {
            self.insertSubview(blurEffectView, at: 0)
        }

        self.blurEffectView = blurEffectView
    }
}

extension RemoveBlurButton: ThemeUpdatable {
    func update(with theme: Theme) {
        self.tintColor = theme.palette.attachmentsPreviewRemoveItemTint
        self.setImage(
            theme.imageSet.attachmentsPreviewItemRemove.withRenderingMode(.alwaysTemplate),
            for: .normal
        )
    }
}
