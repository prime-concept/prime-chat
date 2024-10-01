import UIKit

final class VideoContentView: UIView {
    var guid: String?
    
    static let fixedHeight: CGFloat = 170
    static let widthSpaceCoeff: CGFloat = 0.9
    static let videoInfoEdges = UIEdgeInsets(top: 4, left: 4, bottom: 0, right: 0)

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    private lazy var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    private lazy var overlayView = UIView()
    private lazy var videoInfoView = VideoInfoView()

    private lazy var circleProgressView = CircleProgressView()

    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(self.gestureRecognized(_:))
        )
        return recognizer
    }()

    private var themeProvider: ThemeProvider?

    private var widthCoeff: CGFloat = 0.0

    var onTap: (() -> Void)?

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)

        self.setupSubviews()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.frame = self.bounds
        self.blurView.frame = self.bounds
        self.overlayView.frame = self.bounds

        self.circleProgressView.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        self.circleProgressView.center = self.center

        self.videoInfoView.frame = CGRect(
            x: Self.videoInfoEdges.left,
            y: Self.videoInfoEdges.top,
            width: self.videoInfoView.bounds.width,
            height: self.videoInfoView.bounds.height
        )
    }

    func update(with model: Model) {
        if let size = model.size, size.width <= size.height {
            self.widthCoeff = size.width / (size.height > 0 ? size.height : 1.0)
        } else {
            self.widthCoeff = 1.0
        }

        if model.progress != nil {
            if let image = model.image {
                self.imageView.image = image

                self.overlayView.alpha = 1
                self.blurView.alpha = 0
            } else if let image = model.blur {
                self.imageView.image = image

                self.overlayView.alpha = 0
                self.blurView.alpha = 1
            }
        } else {
            if let image = model.image {
                UIView.animate(withDuration: 0.25) {
                    self.blurView.alpha = 0.0
                }
                self.imageView.image = image
            } else if let image = model.blur {
                self.blurView.alpha = 1
                self.imageView.image = image
            }
        }
        
        let progress = model.progress ?? -1
        let isLoading =  progress > 0 && progress < 1

        self.circleProgressView.isHidden = !isLoading
        self.overlayView.isHidden = !isLoading
        self.videoInfoView.isHidden = isLoading

        if isLoading {
            self.circleProgressView.startLoading()
            self.circleProgressView.progress = CGFloat(progress)
        } else {
            self.circleProgressView.stopLoading()
        }

        let timeString: String? = {
            guard let videoDuration = model.duration else {
                return "video".localized
            }
            let time = Int(videoDuration)
            let minutes = Int(time / 60)
            let seconds = Int(time % 60)
            return "\(minutes)" + ":" + (seconds >= 10 ? "\(seconds)" : "0\(seconds)")
        }()

        self.videoInfoView.update(with: timeString)
        // Set info view size here – in layoutSubviews() we will only reposition it
        let videoInfoViewSize = VideoInfoView.size(for: timeString)
        self.videoInfoView.frame.size = videoInfoViewSize
        self.videoInfoView.setNeedsLayout()
    }

    // MARK: - Private

    private func setupSubviews() {
        self.clipsToBounds = true
        
        self.addSubview(self.imageView)
        self.addSubview(self.blurView)
        self.addSubview(self.overlayView)
        self.addSubview(self.circleProgressView)
        self.addSubview(self.videoInfoView)

        self.reset()

        self.circleProgressView.lineWidth = 3

        self.addGestureRecognizer(self.tapRecognizer)
    }

    @objc
    private func gestureRecognized(_ recognizer: UITapGestureRecognizer) {
        self.onTap?()
    }

    // MARK: - Model

    struct Model {
        let blur: UIImage?
        let image: UIImage?
        let progress: Float?
        let size: CGSize?
        let duration: Double?
    }
}

// MARK: - ThemeUpdatable

extension VideoContentView: ThemeUpdatable {
    func update(with theme: Theme) {
        self.circleProgressView.progressColor = theme.palette.imageBubbleProgress
        self.circleProgressView.untrackedColor = theme.palette.imageBubbleProgressUntracked

        self.blurView.backgroundColor = theme.palette.imageBubbleBlurColor
        self.overlayView.backgroundColor = theme.palette.imageBubbleBlurColor
        self.imageView.backgroundColor = theme.palette.imageBubbleEmpty
    }
}

// MARK: - MessageContentViewProtocol

extension VideoContentView: MessageContentViewProtocol {
    var shouldAddBorder: Bool {
        return false
    }

    var shouldAddInfoViewPad: Bool {
        return true
    }

    func currentContentWidth(constrainedBy width: CGFloat, infoViewArea: CGSize) -> CGFloat {
        return width * self.widthCoeff * Self.widthSpaceCoeff
    }

    func reset() {
        self.imageView.image = nil
        self.circleProgressView.stopLoading()

        self.circleProgressView.isHidden = true
        self.overlayView.alpha = 0
        self.blurView.alpha = 0
        self.circleProgressView.progress = 0.0
    }

    func updateInfoViewFrame(_ frame: CGRect) { }

    func setLongPressHandler(_ handler: @escaping () -> Void) -> Bool { false }
}
