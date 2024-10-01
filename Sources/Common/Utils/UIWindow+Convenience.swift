import UIKit

extension UIWindow {
    static var keyWindow: Self? {
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first as? Self
    }
}
