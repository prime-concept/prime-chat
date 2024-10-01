import UIKit

final class CircleProgressView: UIView {
    private lazy var backgroundLayer: CAShapeLayer = {
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineCap = .round
        backgroundLayer.lineWidth = self.lineWidth
        return backgroundLayer
    }()

    private lazy var progressLayer: CAShapeLayer = {
        let progressLayer = CAShapeLayer()
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = self.lineWidth
        progressLayer.strokeEnd = 0
        return progressLayer
    }()

    var untrackedColor: UIColor? {
        didSet {
            self.backgroundLayer.strokeColor = self.untrackedColor?.cgColor
        }
    }

    var progressColor: UIColor? {
        didSet {
            self.progressLayer.strokeColor = self.progressColor?.cgColor
        }
    }

    var lineWidth: CGFloat = 0 {
        didSet {
            self.backgroundLayer.lineWidth = self.lineWidth
            self.progressLayer.lineWidth = self.lineWidth
        }
    }

    var progress: CGFloat = 0 {
        didSet {
            guard self.progress >= 0, self.progress <= 1 else {
                return
            }

            let progressAnimation = CABasicAnimation(keyPath: "strokeEnd")
            progressAnimation.toValue = self.progress
            progressAnimation.fillMode = .forwards
            progressAnimation.duration = 0.25
            progressAnimation.isRemovedOnCompletion = true

            self.progressLayer.add(progressAnimation, forKey: "progress")
            self.progressLayer.strokeEnd = self.progress
            self.updatePath()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    override func layoutSubviews() {
        super.layoutSubviews()

        self.backgroundLayer.frame = self.bounds
        self.progressLayer.frame = self.bounds

        self.updatePath()
    }

    func startLoading() {
        if self.progressLayer.animation(forKey: "rotationAnimation") != nil {
            return
        }
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(value: 2 * Float.pi)
        rotationAnimation.duration = 1.5
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = .greatestFiniteMagnitude

        self.progressLayer.add(rotationAnimation, forKey: "rotationAnimation")
    }

    func stopLoading() {
        self.progressLayer.removeAllAnimations()
    }

    // MARK: - Private

    private func setupView() {
        self.layer.addSublayer(self.backgroundLayer)
        self.layer.addSublayer(self.progressLayer)
    }

    private func updatePath() {
        let circularPath = UIBezierPath(
            arcCenter: CGPoint(x: self.bounds.midX, y: self.bounds.midY),
            radius: self.bounds.width / 2,
            startAngle: -.pi / 2,
            endAngle: 2 * .pi,
            clockwise: true
        )

        self.backgroundLayer.path = circularPath.cgPath
        self.progressLayer.path = circularPath.cgPath
    }
}
