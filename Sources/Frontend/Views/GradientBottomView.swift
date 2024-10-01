import UIKit

final class GradientBottomView: UIView {
    private enum Appearance {
        static let cornerRadii = CGSize(width: 8, height: 8)
    }

    var shoundRoundBottomCorners = false

    private var bottomGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.6).cgColor
        ]
        return layer
    }()

    private let roundCornersLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        self.bottomGradientLayer.frame = self.bounds

        if self.shoundRoundBottomCorners {
            self.roundCornersLayer.bounds = self.frame
            self.roundCornersLayer.position = self.center
            self.roundCornersLayer.path = UIBezierPath(
                roundedRect: self.bounds,
                byRoundingCorners: [.bottomLeft, .bottomRight],
                cornerRadii: Appearance.cornerRadii
            ).cgPath

            self.layer.mask = self.roundCornersLayer
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.layer.addSublayer(self.bottomGradientLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
