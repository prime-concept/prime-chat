import UIKit

final class MessageGrowingTextView: UITextView {
    var onTextChange: ((String) -> Void)?
    var onHeightChange: ((CGFloat) -> Void)?
    var onTextBeginEditing: (() -> Void)?
    var onTextEndEditing: (() -> Void)?

    private var mayListenToTextDidChange = true
    private lazy var textListenerDebouncer = Debouncer(timeout: 0.1) { [weak self] in
        self?.mayListenToTextDidChange = true
    }

    func ignoreTextEditedNotification() {
        self.mayListenToTextDidChange = false
        self.textListenerDebouncer.reset()
    }

    // swiftlint:disable:next implicitly_unwrapped_optional
    override var text: String! {
        didSet {
            self.setNeedsDisplay()
        }
    }

    private var heightConstraint: NSLayoutConstraint?

    var minHeight: CGFloat = 0 {
        didSet {
            self.forceLayoutSubviews()
        }
    }

    var maxHeight: CGFloat = 0 {
        didSet {
            self.forceLayoutSubviews()
        }
    }

    var placeholder: String? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    var placeholderColor = UIColor.black {
        didSet {
            self.setNeedsDisplay()
        }
    }

    var lineHeight: CGFloat? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    var baselineOffset: CGFloat? {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override var textColor: UIColor? {
        didSet {
            self.fixedFontColor = self.textColor
        }
    }

    private var fixedFontColor: UIColor?

    private var oldText = ""
    private var oldSize = CGSize.zero
    private var shouldScrollAfterHeightChanged = false

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func commonInit() {
        self.contentMode = .redraw
        self.associateConstraints()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.textDidBeginEditing),
            name: UITextView.textDidBeginEditingNotification,
            object: self
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.textDidEndEditing),
            name: UITextView.textDidEndEditingNotification,
            object: self
        )
    }

    private func associateConstraints() {
        for constraint in self.constraints where constraint.firstAttribute == .height && constraint.relation == .equal {
            self.heightConstraint = constraint
        }
    }

    private func forceLayoutSubviews() {
        self.oldSize = .zero
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if self.text == self.oldText && self.bounds.size == self.oldSize {
            return
        }

        self.oldText = self.text
        self.oldSize = self.bounds.size

        let size = self.sizeThatFits(CGSize(width: self.bounds.size.width, height: .greatestFiniteMagnitude))

        var height = size.height
        height = self.minHeight > 0 ? max(height, self.minHeight) : height
        height = self.maxHeight > 0 ? min(height, self.maxHeight) : height

        if self.heightConstraint == nil {
            let heightConstraint = NSLayoutConstraint(
                item: self,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: height
            )
            self.addConstraint(heightConstraint)

            self.heightConstraint = heightConstraint
        }

        if height != self.heightConstraint?.constant {
            self.shouldScrollAfterHeightChanged = true
            self.heightConstraint?.constant = height
            self.onHeightChange?(height)
        } else if self.shouldScrollAfterHeightChanged {
            self.shouldScrollAfterHeightChanged = false
            self.scrollToCorrectPosition()
        }
    }

    private func scrollToCorrectPosition() {
        if self.isFirstResponder {
            self.scrollRangeToVisible(NSRange(location: -1, length: 0)) // Scroll to bottom
        } else {
            self.scrollRangeToVisible(NSRange(location: 0, length: 0)) // Scroll to top
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard self.text.isEmpty else {
            return
        }

        let lineHeight = self.lineHeight ?? self.font?.lineHeight ?? 0
        let baselineOffset = self.baselineOffset ?? 0
        let topInset = ((rect.size.height - lineHeight - baselineOffset) / 2).rounded(.down)
        self.textContainerInset = UIEdgeInsets(top: topInset, left: 0, bottom: topInset, right: 0)

        let xValue: CGFloat = self.textContainerInset.left + self.textContainer.lineFragmentPadding
        let yValue: CGFloat = self.textContainerInset.top
        let width = rect.size.width - xValue - self.textContainerInset.right
        let height = rect.size.height - yValue - self.textContainerInset.bottom
        let placeholderRect = CGRect(x: xValue, y: yValue, width: width, height: height)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = self.textAlignment

        if let lineHeight = self.lineHeight {
            paragraphStyle.lineHeight = lineHeight
        }

        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: self.placeholderColor,
            .paragraphStyle: paragraphStyle
        ]
        if let font = self.font {
            attributes[.font] = font
        }
        attributes[.baselineOffset] = baselineOffset

        self.placeholder?.draw(in: placeholderRect, withAttributes: attributes)
    }

    @objc
    func textDidEndEditing(notification: Notification) {
        guard let sender = notification.object as? MessageGrowingTextView, sender === self else {
            return
        }

        self.text = self.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.setNeedsDisplay()
        self.scrollToCorrectPosition()

        self.onTextEndEditing?()
    }

    @objc
    func textDidChange(notification: Notification) {
        let sender = notification.object as? MessageGrowingTextView
        
        guard sender === self, let font = self.font else {
            return
        }

        let text = self.text ?? ""

        defer {
            self.onTextChange?(text)
        }

        guard self.mayListenToTextDidChange else {
            return
        }

        self.setNeedsDisplay()

        let lineHeight = self.lineHeight ?? self.font?.lineHeight ?? 0.0

        let oldString = self.attributedText
        let newString = text.attributed(
            with: font,
            lineHeight: lineHeight,
            baselineOffset: self.baselineOffset ?? 0
        )

        self.textColor = self.fixedFontColor

        if oldString == newString {
            return
        }

        self.set(
            text: text,
            font: font,
            lineHeight: lineHeight,
            baselineOffset: self.baselineOffset ?? 0
        )
    }

    @objc
    func textDidBeginEditing(notification: Notification) {
        guard let sender = notification.object as? MessageGrowingTextView,
              sender === self else {
            return
        }

        // Tricky way to refresh cursor height at first focus
        let font = self.font ?? .systemFont(ofSize: 15)
        let lineHeight = self.lineHeight ?? self.font?.lineHeight ?? 15
        let baselineOffset = self.baselineOffset ?? 0

        if self.text.isEmpty && self.attributedText.string.isEmpty {
            self.set(text: ".", font: font, lineHeight: lineHeight, baselineOffset: baselineOffset)
            self.set(text: "", font: font, lineHeight: lineHeight, baselineOffset: baselineOffset)
        }
        self.textColor = self.fixedFontColor

        self.onTextBeginEditing?()
    }

    func setPreinstalledText(_ text: String) {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                var notificationBegin = Notification(name: UITextView.textDidBeginEditingNotification)
                notificationBegin.object = self

                var notificationChange = Notification(name: UITextView.textDidChangeNotification)
                notificationChange.object = self

                var notificationEditing = Notification(name: UITextView.textDidEndEditingNotification)
                notificationEditing.object = self

                self.textDidBeginEditing(notification: notificationBegin)

                self.text = text
                self.textDidChange(notification: notificationChange)

                self.textDidEndEditing(notification: notificationEditing)
            }
        }
    }
}
