import UIKit
import MobileCoreServices

final class DefaultDocumentPickerModule: UIDocumentPickerViewController, PickerModule {
    static let listItem = Optional(PickerListItem(icon: UIImage(), title: "file".localized))

    static let shouldPresentWithNavigationController = false

    static var resultContentTypes: [MessageContent.Type] {
        return [DocumentContent.self]
    }

    weak var pickerDelegate: PickerDelegate?

    var viewController: UIViewController { self }

    init(dependencies: PickerModuleDependencies) {
        super.init(
            documentTypes: [
                String(kUTTypeText),
                String(kUTTypeContent),
                String(kUTTypeItem),
                String(kUTTypeData)
            ],
            in: .import
        )

        if #available(iOS 11.0, *) {
            self.allowsMultipleSelection = false
        }
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

extension DefaultDocumentPickerModule: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let documentURL = urls.first else { return }

        self.pickerDelegate?.sendContent(sender: DocumentContentSender(sourceContentURL: documentURL))
    }
}
