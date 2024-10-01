import UIKit

extension NSMutableParagraphStyle {
    
    var lineHeight: CGFloat {
        get { self.minimumLineHeight }
        set {
            self.minimumLineHeight = newValue
            self.maximumLineHeight = newValue
        }
    }
}

extension UILabel {
    private func set(text: String?, font: UIFont, lineHeight: CGFloat? = nil, baselineOffset: CGFloat) {
        let paragraph = NSMutableParagraphStyle()

        if let lineHeight = lineHeight {
            paragraph.lineSpacing = 0
            paragraph.lineHeight = lineHeight
        }

        self.attributedText = NSAttributedString(
            string: text ?? "",
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .baselineOffset: baselineOffset
            ]
        )
    }

    func set(text: String?, with fontDescriptor: FontDescriptor) {
        self.set(
            text: text,
            font: fontDescriptor.font,
            lineHeight: fontDescriptor.lineHeight,
            baselineOffset: fontDescriptor.baselineOffset
        )
    }
}

extension UITextView {
    func set(text: String?, font: UIFont, lineHeight: CGFloat? = nil, baselineOffset: CGFloat) {
        self.attributedText = (text ?? "")
            .attributed(with: font, lineHeight: lineHeight, baselineOffset: baselineOffset)
    }
}

extension String {
    func attributed(
        with font: UIFont,
        lineHeight: CGFloat? = nil,
        baselineOffset: CGFloat
    ) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()

        if let lineHeight = lineHeight {
            paragraph.lineSpacing = 0
            paragraph.lineHeight = lineHeight
        }

        let string = NSAttributedString(
            string: self,
            attributes: [
                .font: font,
                .paragraphStyle: paragraph,
                .baselineOffset: baselineOffset
            ]
        )

        return string
    }
}
