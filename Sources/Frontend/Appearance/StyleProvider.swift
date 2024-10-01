import UIKit

/// Wrapper for all element's style providers
public protocol StyleProvider {
    var messagesCell: MessagesCellStyleProvider.Type { get }
}

extension StyleProvider {
    public var messagesCell: MessagesCellStyleProvider.Type { DefaultMessagesCellStyleProvider.self }
}

// MARK: - MessagesCellStyleProvider

public protocol MessagesCellStyleProvider: AnyObject {
    static func updateStyle(
        of bubbleView: UIView,
        bubbleBorderLayer: CAShapeLayer,
        for meta: MessageContainerModelMeta
    )
}

public extension MessagesCellStyleProvider {
    static func updateStyle(
        of bubbleView: UIView,
        bubbleBorderLayer: CAShapeLayer,
        for meta: MessageContainerModelMeta
    ) {
        bubbleView.clipsToBounds = true
        bubbleView.layer.cornerRadius = 8

        bubbleBorderLayer.path = UIBezierPath(roundedRect: bubbleView.bounds, cornerRadius: 8).cgPath
    }
}

final class DefaultMessagesCellStyleProvider: MessagesCellStyleProvider { }
