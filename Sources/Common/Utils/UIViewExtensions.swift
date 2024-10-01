import UIKit

extension UIView {
    func pch_highlight() {
        UIView.animate(withDuration: 0.15) {
            self.subviews.forEach { $0.alpha = 0.5 }
        }
    }

    func pch_unhighlight() {
        UIView.animate(withDuration: 0.15) {
            self.subviews.forEach { $0.alpha = 1.0 }
        }
    }

    func pch_defaultTapGestureHandler(_ recognizer: UIGestureRecognizer, action: () -> Void) {
        switch recognizer.state {
        case .began:
            self.pch_highlight()
        case .failed, .cancelled:
            self.pch_unhighlight()
        case .ended:
            let point = recognizer.location(in: self)
            if self.bounds.contains(point) {
                action()
            }
            self.pch_unhighlight()
        default:
            break
        }
    }
}
