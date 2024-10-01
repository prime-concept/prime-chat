import UIKit

public struct MessagesListAssembly {
    static func make(
        contentRenderers: [ContentRenderer.Type],
        messageGuidToOpen: String? = nil,
        delegate: MessagesListDelegateProtocol?
    ) -> MessagesListViewControllerProtocol {
        let presenter = MessagesListPresenter(
            moduleDelegate: delegate,
            messageGuidToOpen: messageGuidToOpen
        )

        let viewController = MessagesListViewController(presenter: presenter)
        viewController.setup(for: contentRenderers)

        presenter.viewController = viewController

        return viewController
    }
}
