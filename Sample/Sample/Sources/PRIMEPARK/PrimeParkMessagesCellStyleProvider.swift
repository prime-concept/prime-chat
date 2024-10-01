import UIKit
import ChatSDK

final class PrimeParkMessagesCellStyleProvider: MessagesCellStyleProvider {
    static func updateStyle(
        of bubbleView: UIView,
        bubbleBorderLayer: CAShapeLayer,
        for meta: MessageContainerModelMeta
    ) {
        if bubbleView.bounds.isEmpty {
            return
        }

        let cornerRadiusDefault: CGFloat = 12
        let cornerRadiusSmall: CGFloat = 6

        let cornerPath: UIBezierPath
        switch meta.author {
        case .me:
            cornerPath = UIBezierPath.pch_make(
                with: bubbleView.bounds,
                topLeftRadius: cornerRadiusDefault,
                topRightRadius: cornerRadiusDefault,
                bottomLeftRadius: cornerRadiusDefault,
                bottomRightRadius: meta.isNextMessageOfSameUser ? cornerRadiusDefault : cornerRadiusSmall
            )
        case .anotherUser:
            cornerPath = UIBezierPath.pch_make(
                with: bubbleView.bounds,
                topLeftRadius: cornerRadiusDefault,
                topRightRadius: cornerRadiusDefault,
                bottomLeftRadius: meta.isNextMessageOfSameUser ? cornerRadiusDefault : cornerRadiusSmall,
                bottomRightRadius: cornerRadiusDefault
            )
        }

        let pathMask = CAShapeLayer()
        pathMask.path = cornerPath.cgPath

        bubbleView.layer.mask = pathMask
        bubbleBorderLayer.path = cornerPath.cgPath
    }
}
