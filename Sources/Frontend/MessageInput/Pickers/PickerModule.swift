import UIKit

public struct PickerListItem {
    let icon: UIImage
    let title: String
}

public protocol PickerDelegate: AnyObject {
    func sendContent(sender: ContentSender)
    func attachContent(senders: [ContentSender])
}

public struct PickerModuleDependencies {
    let locationService: LocationServiceProtocol
}

/// Module for sending some type of content
public protocol PickerModule: AnyObject {
    static var listItem: PickerListItem? { get }

    /// Optional property to define messages types provided by module. Used by feature flags to hide some pickers
    static var resultContentTypes: [MessageContent.Type] { get }

    var pickerDelegate: PickerDelegate? { get set }

    static var shouldPresentWithNavigationController: Bool { get }
    static var modalPresentationStyle: UIModalPresentationStyle { get }

    var viewController: UIViewController { get }

    init(dependencies: PickerModuleDependencies)
}

public extension PickerModule {
    static var shouldPresentWithNavigationController: Bool {
        return true
    }

    static var modalPresentationStyle: UIModalPresentationStyle {
        return .currentContext
    }

    static var resultContentTypes: [MessageContent.Type] {
        return []
    }

    static func hasResult(oneOf types: [MessageContent.Type]) -> Bool {
        let givenTypeStrings = Set(types.map { $0.messageType })
        let targetTypeStrings = Set(Self.resultContentTypes.map { $0.messageType })
        return !givenTypeStrings.isDisjoint(with: targetTypeStrings)
    }
}

/// Picker module factory
final class PickerModuleFactory {
    private var modules: [PickerModule.Type] = []

    func register(picker: PickerModule.Type, for messageContentType: MessageContent.Type) {
        self.modules.append(picker)
    }

    func allModules() -> [PickerModule.Type] {
        return self.modules
    }
}
