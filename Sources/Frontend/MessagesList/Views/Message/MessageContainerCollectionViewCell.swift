import UIKit

// It cannot be internal type cause generic class doesn't support static properties
enum MessageContainerCellLayout {
    static let bubbleTopInset: CGFloat = 3.0
    static let bubbleBottomInset: CGFloat = 2.0
    static let bubbleHorizontalFixedInset: CGFloat = 15.0

    static let errorSize = CGSize(width: 20, height: 20)
    static let errorRightMargin: CGFloat = 8.0

    static let authorAlignOffset: CGFloat = 45.0

    static let replyHeight: CGFloat = 45

    static let imageSpacer: CGFloat = 8

    /// Padding insets contains only bottom- and right- values
    static let infoViewPaddingInsets = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 4)
}

final class MessageContainerCollectionViewCell<ContentViewType: MessageContentViewProtocol>: UICollectionViewCell {
    private let bubbleView = UIView()
    private let infoView = MessageInfoView()
    private(set) lazy var messageContentView = ContentViewType()

    private let errorView = ErrorView()
    private let swipeView = MessageContainerSwipeView()
    private let replyView = MessageReplyView()

    private lazy var bubbleBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineWidth = 1
        return layer
    }()

    private var meta: MessageContainerModelMeta?
    private var themeProvider: ThemeProvider?

    static var reuseIdentifier: String {
        return "MessageContainerCollectionViewCell_\(ContentViewType.self.description())"
    }

    var isFailed: Bool {
        self.meta?.isFailed == true
    }

    var isIncome: Bool {
        self.meta?.author == .anotherUser
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swiftlint:disable:next function_body_length
    override func layoutSubviews() {
        super.layoutSubviews()

        let contentViewBounds = self.contentView.bounds
        let errorViewSize = MessageContainerCellLayout.errorSize
        let smallHorizontalInset = MessageContainerCellLayout.bubbleHorizontalFixedInset

        let maxWidthForBubble = contentViewBounds.width
        - MessageContainerCellLayout.authorAlignOffset
        - smallHorizontalInset
        - (self.isFailed ? errorViewSize.width + MessageContainerCellLayout.errorRightMargin : 0)
        let infoViewBounds = self.infoView.bounds
        var currentContentWidth = self.messageContentView.currentContentWidth(
            constrainedBy: maxWidthForBubble,
            infoViewArea: infoViewBounds.size
        )

        let shouldAddReply = self.meta?.replyMeta != nil
        if shouldAddReply {
            var replyWidth = self.replyView.intrinsicContentSize.width
            replyWidth = min(maxWidthForBubble, replyWidth)
            currentContentWidth = max(replyWidth, currentContentWidth)
        }

        let xOffset = self.isIncome
        ? smallHorizontalInset
        : contentViewBounds.width
        - currentContentWidth
        - smallHorizontalInset
        self.swipeView.frame = self.contentView.bounds

        self.bubbleView.frame = CGRect(
            x: xOffset,
            y: MessageContainerCellLayout.bubbleTopInset,
            width: currentContentWidth,
            height: contentViewBounds.height
            - MessageContainerCellLayout.bubbleTopInset
            - MessageContainerCellLayout.bubbleBottomInset
        )

        let bubbleViewBounds = self.bubbleView.bounds

        self.errorView.frame = CGRect(
            x: xOffset - errorViewSize.width - MessageContainerCellLayout.errorRightMargin,
            y: contentViewBounds.height / 2 - errorViewSize.height / 2,
            width: errorViewSize.width,
            height: errorViewSize.height
        )

        self.infoView.frame = CGRect(
            x: bubbleViewBounds.width
            - infoViewBounds.width
            - MessageContainerCellLayout.infoViewPaddingInsets.right,
            y: bubbleViewBounds.height
            - infoViewBounds.height
            - MessageContainerCellLayout.infoViewPaddingInsets.bottom,
            width: infoViewBounds.width,
            height: infoViewBounds.height
        )

        self.messageContentView.updateInfoViewFrame(self.infoView.frame)
        self.infoView.useBackgroundPad = self.messageContentView.shouldAddInfoViewPad

        self.replyView.isHidden = !shouldAddReply
        var replyViewHeight = shouldAddReply ? MessageContainerCellLayout.replyHeight : 0

        if shouldAddReply && self.messageContentView is ImageContentView {
            replyViewHeight += MessageContainerCellLayout.imageSpacer
        }

        self.replyView.frame = CGRect(
            x: 0,
            y: 0,
            width: bubbleViewBounds.width,
            height: replyViewHeight
        )

        var contentHeight = bubbleViewBounds.height
        if replyView.isHidden == false {
            contentHeight -= replyView.bounds.height
        }

        self.messageContentView.frame = CGRect(
            x: 0,
            y: shouldAddReply ? self.replyView.frame.maxY : 0,
            width: bubbleViewBounds.width,
            height: contentHeight
        )

        self.bubbleBorderLayer.frame = bubbleViewBounds
        self.bubbleBorderLayer.lineWidth = self.messageContentView.shouldAddBorder ? 1.0 : 0.5

        if let meta = self.meta {
            self.themeProvider?.current.styleProvider.messagesCell.updateStyle(
                of: self.bubbleView,
                bubbleBorderLayer: self.bubbleBorderLayer,
                for: meta
            )
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.bubbleView.frame = .zero
        self.errorView.frame = .zero
        self.messageContentView.frame = .zero
        self.swipeView.frame = .zero
        self.replyView.frame = .zero

        self.infoView.reset()
        self.messageContentView.reset()

        self.meta = nil
        self.onLongPress = nil
    }

    private lazy var guidLabel: UILabel = {
        let label = UILabel()
        label.textColor = .red.withAlphaComponent(0.5)
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.font = .systemFont(ofSize: 22)
        label.textAlignment = .center

        self.contentView.addSubview(label)
        label.make([.leading, .trailing, .centerY], .equalToSuperview, [10, -10, 0])

        return label
    }()

    func configure(with model: MessageContainerModel<ContentViewType>) {
        self.configureCommonInfo(with: model)
        self.configureContent(with: model)
        self.configureErrorView(with: model)
        self.configureSwipeView(with: model)
        self.configureReplyView(with: model)
        self.configureLongPress(with: model)

        if UserDefaults.standard.bool(forKey: "MESSAGE_GUID_SHOWN") {
            self.guidLabel.text = model.uid
        }

        self.setNeedsLayout()
    }

    static func calculateHeight(with contentHeight: CGFloat) -> CGFloat {
        return contentHeight
        + MessageContainerCellLayout.bubbleBottomInset
        + MessageContainerCellLayout.bubbleTopInset
    }

    static func widthForContent(cellWidth: CGFloat, meta: MessageContainerModelMeta) -> CGFloat {
        let errorViewWidth = meta.isFailed
        ? MessageContainerCellLayout.errorSize.width + MessageContainerCellLayout.errorRightMargin
        : 0
        let width = cellWidth
        - MessageContainerCellLayout.bubbleHorizontalFixedInset
        - MessageContainerCellLayout.authorAlignOffset
        - errorViewWidth
        return max(0, width)
    }

    // MARK: - Private

    private func configureCommonInfo(with model: MessageContainerModel<ContentViewType>) {
        self.meta = model.meta

        self.infoView.update(with: model.meta)
        // Set info view size here – in layoutSubviews() we will only reposition it
        let infoViewSize = MessageInfoView.size(for: model.meta)
        self.infoView.frame.size = infoViewSize
        self.infoView.setNeedsLayout()

        self.themeProvider.flatMap { self.update(with: $0.current) }
    }

    private func configureContent(with model: MessageContainerModel<ContentViewType>) {
        self.messageContentView.guid = model.uid

        let configurator = model.contentConfigurator
        configurator(self.messageContentView)
    }

    private func configureErrorView(with model: MessageContainerModel<ContentViewType>) {
        self.errorView.isHidden = !model.meta.isFailed
        self.errorView.onClick = {
            self.errorView.isUserInteractionEnabled = false
            model.actions.onRetry?()
            delay(2) { [weak self] in
                self?.errorView.isUserInteractionEnabled = true
            }
        }
    }

    private func configureSwipeView(with model: MessageContainerModel<ContentViewType>) {
        self.swipeView.onCompletedSwipe = { model.actions.onReply?() }
    }

    private func configureReplyView(with model: MessageContainerModel<ContentViewType>) {
        model.meta.replyMeta.flatMap {
            self.replyView.configure(with: $0, isIncome: self.isIncome)
        }
    }

    private var onLongPress: (() -> Void)?
    private func configureLongPress(with model: MessageContainerModel<ContentViewType>) {
        if let onLongPress = model.actions.onLongPress,
           self.messageContentView.setLongPressHandler(onLongPress) {
            return
        }

        let recognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(messageContentLongPressRecognized(_:))
        )
        self.messageContentView.addGestureRecognizer(recognizer)
        self.messageContentView.isUserInteractionEnabled = true
        self.onLongPress = model.actions.onLongPress
    }

    private func setupView() {
        self.contentView.addSubview(self.swipeView)
        self.swipeView.contentView.addSubview(self.bubbleView)
        self.bubbleView.addSubview(self.replyView)
        self.bubbleView.addSubview(self.messageContentView)
        self.bubbleView.addSubview(self.infoView)
        self.bubbleView.layer.addSublayer(self.bubbleBorderLayer)

        self.swipeView.contentView.addSubview(self.errorView)
    }

    private var mayCallOnLongPress = false

    @objc
    private func messageContentLongPressRecognized(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            self.mayCallOnLongPress = true
            self.zoomBubbleViewIn()
            return
        }

        if recognizer.state == .changed || recognizer.state == .ended {
            if self.mayCallOnLongPress {
                self.onLongPress?()
                self.mayCallOnLongPress = false
            }
        }

        self.zoomBubbleViewOutIfNeeded(recognizer)
    }

    private func zoomBubbleViewIn() {
        let oldSize = max(self.bubbleView.bounds.width, self.bubbleView.bounds.height)
        let newSize = oldSize + 8
        let finalScale = newSize / oldSize
        UIView.animate(
            withDuration: 0.1,
            animations: {
                self.bubbleView.transform = CGAffineTransform.identity.scaledBy(x: finalScale, y: finalScale)
            }
        )
    }

    private func zoomBubbleViewOutIfNeeded(_ recognizer: UIGestureRecognizer) {
        if Set([
            UIGestureRecognizer.State.failed,
            UIGestureRecognizer.State.cancelled,
            UIGestureRecognizer.State.ended
        ]).contains(recognizer.state) {
            UIView.animate(
                withDuration: 0.1,
                animations: {
                    self.bubbleView.transform = CGAffineTransform.identity
                },
                completion: nil
            )
        }
    }
}

extension MessageContainerCollectionViewCell: ThemeUpdatable {
    func update(with theme: Theme) {
        self.bubbleView.backgroundColor = self.isIncome
        ? theme.palette.bubbleIncomeBackground
        : theme.palette.bubbleOutcomeBackground
        if self.messageContentView.shouldAddBorder {
            self.bubbleBorderLayer.strokeColor = theme.palette.bubbleBorder.cgColor
            self.bubbleBorderLayer.isHidden = false
        } else if let meta = self.meta {
            let borderColor = meta.author == .me
            ? theme.palette.bubbleOutcomeBorder.cgColor
            : theme.palette.bubbleIncomeBorder.cgColor
            self.bubbleBorderLayer.strokeColor = borderColor
            self.bubbleBorderLayer.isHidden = borderColor.alpha == 0.0
        } else {
            self.bubbleBorderLayer.isHidden = true
        }
    }
}

// MARK: - Error view

private class ErrorView: UIView, ThemeUpdatable {
    var onClick: (() -> Void)?

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(self.retryButtonClicked), for: .touchUpInside)
        return button
    }()

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
        self.retryButton.frame = self.bounds
    }

    @objc
    private func retryButtonClicked() {
        self.onClick?()
    }

    private func setupView() {
        self.addSubview(self.retryButton)
    }

    // MARK: - ThemeUpdatable

    func update(with theme: Theme) {
        self.retryButton.setImage(theme.imageSet.errorButton.withRenderingMode(.alwaysOriginal), for: .normal)
    }
}
