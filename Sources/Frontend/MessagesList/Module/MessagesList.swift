import UIKit

public protocol MessagesListDelegateProtocol: AnyObject {
    func loadNewerMessages()
    func loadOlderMessages()
    func willDisplayItem(uid: UniqueIdentifierType)
}

final class MessagesListContainer {
    private let chatViewController: MessagesListViewController
    private let messagesListPresenter: MessagesListPresenter

    init(
        contentRenderers: [ContentRenderer.Type],
        messageGuidToOpen: String? = nil,
        delegate: MessagesListDelegateProtocol?
    ) {
        let presenter = MessagesListPresenter(
            moduleDelegate: delegate,
            messageGuidToOpen: messageGuidToOpen
        )

        let viewController = MessagesListViewController(presenter: presenter)
        viewController.setup(for: contentRenderers)

        presenter.viewController = viewController

        self.chatViewController = viewController
        self.messagesListPresenter = presenter
    }
}

extension MessagesListContainer: MessagesList {
    var bottomViewExists: Bool {
        self.chatViewController.bottomViewExists
    }
    
    func addBottomView(_ view: UIView) {
        self.chatViewController.addBottomView(view)
    }
    
    var viewController: UIViewController {
        return self.chatViewController
    }

    func update(with items: [MessagesListItemModelProtocol]) {
        self.messagesListPresenter.update(with: items)
    }

    func adjustContentInsets(top: CGFloat, bottom: CGFloat) {
        self.chatViewController.adjustContentInsets(top: top, bottom: bottom)
    }

    func setOverlay(_ view: UIView) {
        guard let chatView = self.chatViewController.view else {
            fatalError("There MUST be MessagesListViewController's view before setting overlay")
        }
        chatView.addSubview(view)
        view.topAnchor.constraint(equalTo: chatView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: chatView.leadingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: chatView.bottomAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: chatView.rightAnchor).isActive = true
    }
}
