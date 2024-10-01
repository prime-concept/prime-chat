import UIKit
import ContactsUI

final class DefaultContactPickerModule: CNContactPickerViewController, PickerModule {
    static let listItem = Optional(PickerListItem(icon: UIImage(), title: "contact".localized))

    static let shouldPresentWithNavigationController = false

    static var resultContentTypes: [MessageContent.Type] {
        return [ContactContent.self]
    }

    weak var pickerDelegate: PickerDelegate?

    var viewController: UIViewController {
        return self
    }

    init(dependencies: PickerModuleDependencies) {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
}

extension DefaultContactPickerModule: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let content = ContactItem(contact: contact)
        self.pickerDelegate?.sendContent(sender: ContactContentSender(messageContent: content))
    }
}
