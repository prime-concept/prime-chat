import UIKit

/// Providing layout specific details (e.g. paddings)
public protocol LayoutProvider {
    var messageInputHorizontalInset: CGFloat { get }
    var textNormalMessageInsets: UIEdgeInsets { get }
    var textReplyMessageInsets: UIEdgeInsets { get }
    var videoInfoPlayImageRightMargin: CGFloat { get }
}

extension LayoutProvider {
    public var messageInputHorizontalInset: CGFloat { 0.0 }
    public var textNormalMessageInsets: UIEdgeInsets { .init(top: 12, left: 15, bottom: 11, right: 15) }
    public var textReplyMessageInsets: UIEdgeInsets { .init(top: 10, left: 15, bottom: 11, right: 15) }
    public var videoInfoPlayImageRightMargin: CGFloat { 3.0 }
}
