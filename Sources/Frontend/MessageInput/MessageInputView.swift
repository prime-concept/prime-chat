import UIKit

final class MessageInputView: UIView {
    var chatInputAccessoryView: UIView?

    override var inputAccessoryView: UIView? {
        get {
            return self.chatInputAccessoryView
        }
        set {
            self.chatInputAccessoryView = newValue
        }
    }
}
