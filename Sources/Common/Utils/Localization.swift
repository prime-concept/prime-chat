import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(
            self,
            tableName: nil,
            bundle: Bundle.module,
            value: "",
            comment: ""
        )
    }
}
