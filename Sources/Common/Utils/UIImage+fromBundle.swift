import UIKit

extension UIImage {
    static func fromBundle(name: String) -> UIImage {
        guard let image = _fromBundle(name: name) else {
            assertionFailure("Image \(name) not found")
            return UIImage()
        }
        
        return image
    }
    
    static func _fromBundle(name: String) -> UIImage? {
        let currentBundle = Bundle.module
        if let imageFromCurrentBundle = UIImage(named: name, in: currentBundle, compatibleWith: nil) {
            return imageFromCurrentBundle
        } else if
            let assetsBundle = currentBundle.url(forResource: "ChatAssets", withExtension: "bundle")
                .map({ Bundle(url: $0) }),
            let imageFromAssetsBundle = UIImage(named: name, in: assetsBundle, compatibleWith: nil) {
            return imageFromAssetsBundle
        } else {
            return nil
        }
    }

    public static func pch_fromColor(_ color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)

        UIGraphicsBeginImageContext(rect.size)
        defer {
            UIGraphicsEndImageContext()
        }
        let context = UIGraphicsGetCurrentContext()

        context?.setFillColor(color.cgColor)
        context?.fill(rect)

        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            return image
        } else {
            assertionFailure("Invalid context capturing")
            return UIImage()
        }
    }
}
