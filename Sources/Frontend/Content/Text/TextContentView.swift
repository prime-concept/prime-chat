import UIKit

final class TextContentView: UIView, UIGestureRecognizerDelegate {
    var guid: String?
    
    private static var font: FontDescriptor { ThemeProvider.current.fontProvider.messageText }
    private static var normalTextInsets: UIEdgeInsets { ThemeProvider.current.layoutProvider.textNormalMessageInsets }
    private static var replyTextInsets: UIEdgeInsets { ThemeProvider.current.layoutProvider.textReplyMessageInsets }

    private static var paragraphStyle: NSParagraphStyle {
        let  style = NSMutableParagraphStyle()

        if let lineHeight = TextContentView.font.lineHeight {
            style.lineHeight = lineHeight
            style.lineSpacing = 0
        } else {
            style.lineSpacing = 2
        }

        return style
    }
    
    private var onLongPress: (() -> Void)?

    private lazy var textView: ChatTextView = {
        let textView = ChatTextView()
        textView.delegate = self

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressRecognized(_:)))
        longPressRecognizer.delaysTouchesEnded = true
        longPressRecognizer.delegate = self
        textView.addGestureRecognizer(longPressRecognizer)

        UIView.performWithoutAnimation {
            textView.backgroundColor = UIColor.clear
        }

        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = .all
        textView.scrollsToTop = false
        textView.isScrollEnabled = false
        textView.bounces = false
        textView.bouncesZoom = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isExclusiveTouch = true

        textView.textContainerInset = Self.normalTextInsets
        textView.textContainer.lineFragmentPadding = 0

        textView.disableDragInteraction()
        textView.disableLargeContentViewer()

        return textView
    }()

    private var themeProvider: ThemeProvider?
    private var replyMeta: MessageReplyModelMeta?

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

        self.textView.frame = self.bounds
    }

    func update(with text: String, meta: MessageContainerModelMeta) {
        guard let palette = self.themeProvider?.current.palette else {
            return
        }

        let attributedString = NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: Self.paragraphStyle,
                .font: Self.font.font,
                .foregroundColor: meta.author == .me ? palette.bubbleOutcomeText : palette.bubbleIncomeText,
                .baselineOffset: Self.font.baselineOffset
            ]
        )

        if let outcomeLinkColor = palette.textContentOutcomeLinkColor,
           let incomeLinkColor = palette.textContentIncomeLinkColor {
            let color = meta.author == .me ? outcomeLinkColor : incomeLinkColor

            self.textView.linkTextAttributes = [.foregroundColor: color,
                                                .underlineColor: color,
                                                .underlineStyle: NSUnderlineStyle.single]
        }

        self.textView.attributedText = attributedString
        self.textView.textContainerInset = meta.replyMeta == nil
        ? Self.normalTextInsets
        : Self.replyTextInsets
        self.replyMeta = meta.replyMeta
    }

    static func calculateSize(
        for text: String,
        maxWidth: CGFloat,
        hasReply: Bool,
        maxPossibleRightBottomAreaSize: CGSize
    ) -> CGSize {
        let textInsets = hasReply ? self.replyTextInsets : self.normalTextInsets

        let textContainer: NSTextContainer = {
            let width = maxWidth - textInsets.left - textInsets.right

            let size = CGSize(
                width: min(UIScreen.main.bounds.width, width),
                height: .greatestFiniteMagnitude
            )
            let container = NSTextContainer(size: size)
            container.lineFragmentPadding = 0
            return container
        }()

        let textStorage = NSTextStorage(
            string: text,
            attributes: [
                .paragraphStyle: self.paragraphStyle,
                .font: self.font.font,
                NSAttributedString.Key(rawValue: "NSOriginalFont"): self.font.font
            ]
        )

        let layoutManager: NSLayoutManager = {
            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(textContainer)
            // Force layout by calling glyphRange(for:)
            layoutManager.glyphRange(for: textContainer)
            textStorage.addLayoutManager(layoutManager)
            return layoutManager
        }()

        let textBounds = layoutManager.usedRect(for: textContainer).size

        let lastGlyphIndex = layoutManager.glyphIndexForCharacter(at: text.count - 1)
        let lastLineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: lastGlyphIndex, effectiveRange: nil)

        let lineHeight = self.font.lineHeight ?? self.font.font.lineHeight
        let numberOfLines = Int(
            (textBounds.height / max(1.0, lineHeight + self.paragraphStyle.lineSpacing)).rounded(.up)
        )

        let horizontalInset = textInsets.left + textInsets.right
        let verticalInset = textInsets.top + textInsets.bottom

        let mayFitTextAndDateInOneLine =
            textBounds.width + horizontalInset < maxWidth - maxPossibleRightBottomAreaSize.width

        let mayFitLastLineAndDateInSameLine =
            lastLineRect.width + textInsets.right + maxPossibleRightBottomAreaSize.width < textBounds.width

        let stillEnoughWidthForLastLineAndDate =
            lastLineRect.width + horizontalInset + maxPossibleRightBottomAreaSize.width < maxWidth

        if numberOfLines == 1 {
            if mayFitTextAndDateInOneLine {
                /*
                 <text_0> <date>


                 Result:
                 w: <inset> <text> <inset> <date>
                 h: <inset>
                    <text>
                    <inset>
                */
                let width = textBounds.width + maxPossibleRightBottomAreaSize.width + horizontalInset
                return CGSize(
                    width: min(UIScreen.main.bounds.width, width),
                    height: textBounds.height + verticalInset
                )
            }
            /*
             <text______0>
                    <date>


             Result:
             w: <inset> <text> <inset>
             h: <inset>
                <text>
                <date>
                <inset - date>
             */
            return CGSize(
                width: min(UIScreen.main.bounds.width, textBounds.width + horizontalInset),
                height: textBounds.height
                + maxPossibleRightBottomAreaSize.height
                + textInsets.top
                + max(0, textInsets.bottom - maxPossibleRightBottomAreaSize.height)
            )
        }

        if mayFitLastLineAndDateInSameLine {
            /*
             <text________0>
             <text________1>
             ...
             <text_n> <date>


             Result:
             w: <inset> <text> <inset> <date>
             h: <inset>
                <text>
                <inset>
            */
            return CGSize(
                width: min(UIScreen.main.bounds.width, textBounds.width + horizontalInset),
                height: textBounds.height + verticalInset
            )
        }

        if stillEnoughWidthForLastLineAndDate {
            /*
             |--------------|
             <text____0>
             <text____1>
             ...
             <text__n> <date>


             Result:
             w: <inset> <text> <inset> <date>
             h: <inset>
                <text>
                <inset>
            */
            let width = max(textBounds.width, lastLineRect.width)
            + maxPossibleRightBottomAreaSize.width + horizontalInset
            
            return CGSize(
                width: min(maxWidth, width),
                height: textBounds.height + verticalInset
            )
        }

        /*
         <text___0>
         <text___1>
         ...
         <text___n>
             <date>

         Result:
         w: <inset> <text> <inset>
         h: <inset>
            <text>
            <date>
            <inset - date>
         */
        let width = textBounds.width + horizontalInset
        return CGSize(
            width: min(UIScreen.main.bounds.width, width),
            height: textBounds.height + maxPossibleRightBottomAreaSize.height
            + textInsets.top
            + max(0, textInsets.bottom - maxPossibleRightBottomAreaSize.height)
        )
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    // MARK: - Private

    private func setupSubviews() {
        self.addSubview(self.textView)
    }

    private var mayCallOnLongPress = false

    @objc
    private func longPressRecognized(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            self.mayCallOnLongPress = true
            return
        }

        if recognizer.state == .changed || recognizer.state == .ended {
            if self.mayCallOnLongPress {
                self.onLongPress?()
                self.mayCallOnLongPress = false
            }
        }
    }
}

extension TextContentView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange
    ) -> Bool {
        let didOpenURL = Configuration.urlOpeningHandler?(url) ?? false
        return !didOpenURL
    }
}

// MARK: - MessageContentViewProtocol

extension TextContentView: MessageContentViewProtocol {
    var shouldAddBorder: Bool {
        return false
    }

    var shouldAddInfoViewPad: Bool {
        return false
    }

    func currentContentWidth(constrainedBy width: CGFloat, infoViewArea: CGSize) -> CGFloat {
        let widthMessage = Self.calculateSize(
            for: self.textView.text,
            maxWidth: width,
            hasReply: self.replyMeta != nil,
            maxPossibleRightBottomAreaSize: infoViewArea
        ).width

        return widthMessage
    }

    func reset() {
        self.textView.text = nil
    }

    func updateInfoViewFrame(_ frame: CGRect) { }

    func setLongPressHandler(_ handler: @escaping  () -> Void) -> Bool {
        self.onLongPress = handler
        return true
    }
}

// MARK: - ThemeUpdatable

extension TextContentView: ThemeUpdatable {
    func update(with theme: Theme) { }
}

// MARK: - ChatTextView

private final class ChatTextView: UITextView {
    override var canBecomeFirstResponder: Bool {
        return false
    }

    // Optimization from Chatto
    override var gestureRecognizers: [UIGestureRecognizer]? {
        get {
            return super.gestureRecognizers?.filter { gestureRecognizer in
                if #available(iOS 13, *) {
                    return !Self.notAllowedGestureRecognizerNames.contains(gestureRecognizer.name?.base64String ?? "")
                }
                if #available(iOS 11, *),
                   gestureRecognizer.name?.base64String == SystemGestureRecognizerNames.linkTap.rawValue {
                    return true
                }
                if type(of: gestureRecognizer) == UILongPressGestureRecognizer.self,
                   gestureRecognizer.delaysTouchesEnded {
                    return true
                }
                return false
            }
        }
        set {
            super.gestureRecognizers = newValue
        }
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }

    // Optimization from Chatto
    override var selectedRange: NSRange {
        get {
            return NSRange(location: 0, length: 0)
        }
        set {
            // Part of the heaviest stack trace when scrolling (when updating text)
            // See https://github.com/badoo/Chatto/pull/144
        }
    }

    // Optimization from Chatto
    override var contentOffset: CGPoint {
        get {
            return .zero
        }
        set {
            // Part of the heaviest stack trace when scrolling (when bounds are set)
            // See https://github.com/badoo/Chatto/pull/144
        }
    }

    fileprivate func disableDragInteraction() {
        if #available(iOS 11.0, *) {
            self.textDragInteraction?.isEnabled = false
        }
    }

    fileprivate func disableLargeContentViewer() {
#if compiler(>=5.1)
        if #available(iOS 13.0, *) {
            self.showsLargeContentViewer = false
        }
#endif
    }

    private static let notAllowedGestureRecognizerNames: Set<String> = Set(
        [
            SystemGestureRecognizerNames.forcePress.rawValue,
            SystemGestureRecognizerNames.loupe.rawValue
        ]
    )

    private enum SystemGestureRecognizerNames: String {
        // _UIKeyboardTextSelectionGestureForcePress
        case forcePress = "X1VJS2V5Ym9hcmRUZXh0U2VsZWN0aW9uR2VzdHVyZUZvcmNlUHJlc3M="
        // UITextInteractionNameLoupe
        case loupe = "VUlUZXh0SW50ZXJhY3Rpb25OYW1lTG91cGU="
        // UITextInteractionNameLinkTap
        case linkTap = "VUlUZXh0SW50ZXJhY3Rpb25OYW1lTGlua1RhcA=="
    }
}

extension String {
    var base64String: String? {
        return self.data(using: .utf8)?.base64EncodedString()
    }

    func width(constrainedBy height: CGFloat, maxWidth: CGFloat, font: UIFont, lineHeight: CGFloat? = nil) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()

        if let lineHeight = lineHeight {
            paragraph.lineHeight = lineHeight
        }

        let width = min(UIScreen.main.bounds.width, maxWidth)

        let constraintRect = CGSize(width: width, height: height)
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font, .paragraphStyle: paragraph],
            context: nil
        )

        return ceil(boundingBox.width)
    }

    func width(constrainedBy height: CGFloat, maxWidth: CGFloat, fontDescriptor: FontDescriptor) -> CGFloat {
        self.width(
            constrainedBy: height,
            maxWidth: maxWidth,
            font: fontDescriptor.font,
            lineHeight: fontDescriptor.lineHeight
        )
    }
}
