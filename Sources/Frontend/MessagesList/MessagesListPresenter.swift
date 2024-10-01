import Foundation

protocol MessagesListPresenterProtocol {
    func loadOlderMessages()
    func loadNewerMessages()
    func viewController(
        _ controller: MessagesListViewControllerProtocol,
        didUpdateWith items: [MessagesListItemModelProtocol]
    )

    func willDisplayItem(uid: UniqueIdentifierType)
    func didAppear()
}

final class MessagesListPresenter: MessagesListPresenterProtocol {
    weak var viewController: MessagesListViewControllerProtocol?
    private weak var delegate: MessagesListDelegateProtocol?
    
    private var messageGuidToOpen: String? = nil
    private var mayShowMessageGuidContentOpeningLoader: Bool = true
    
    private lazy var messageGuidToOpenDebouncer = Debouncer(timeout: 0.3) {
        DispatchQueue.main.async { [weak self] in
            self?.scrollAndOpenContentForMessageGuidIfNeeded()
        }
    }

    init(
		moduleDelegate: MessagesListDelegateProtocol?,
		messageGuidToOpen: String? = nil
	) {
        self.delegate = moduleDelegate
		self.messageGuidToOpen = messageGuidToOpen
    }

    func didAppear() {
        showMessageGuidContentOpeningIfNeeded()
    }

    func update(with items: [MessagesListItemModelProtocol]) {
        self.viewController?.stopRefreshLoader()
		self.viewController?.update(with: items)
    }

	func viewController(
		_ controller: MessagesListViewControllerProtocol,
		didUpdateWith items: [MessagesListItemModelProtocol]
	) {
        DispatchQueue.main.async {
            if let guid = self.messageGuidToOpen {
                self.openMessage(by: guid, in: items)
            }
        }
	}

	private func openMessage(by guid: String, in items: [MessagesListItemModelProtocol]) {
		guard items.contains(where: { $0.uid.contains(regex: guid) }) else {
			return
		}

        self.messageGuidToOpenDebouncer.reset()
	}

    private func scrollAndOpenContentForMessageGuidIfNeeded() {
        guard let guid = messageGuidToOpen else { return }

        self.viewController?.scroll(to: guid) { _ in
            guard let guid = self.messageGuidToOpen else { return }
            self.messageGuidToOpen = nil

            self.viewController?.openContent(for: guid) {
                self.mayShowMessageGuidContentOpeningLoader = false
                Configuration.hideLoadingIndicator?(self.viewController)
            }
        }
    }

    private func showMessageGuidContentOpeningIfNeeded() {
        if messageGuidToOpen == nil { return }
        
        delay(1) { [weak self] in
            guard let self else { return }

            if self.mayShowMessageGuidContentOpeningLoader {
                self.mayShowMessageGuidContentOpeningLoader = false
                Configuration.showLoadingIndicator?(self.viewController)
            }
        }
    }

    func loadOlderMessages() {
        /*
         Мы на пути изнурительного прокидывания.
         Сейчас мы дернем loadOlderMessages у своего делегата - ChatPresenter.
         ChatPresenter это общий знаменатель между контроллером ленты и контроллером поля ввода текста.
         У ChatPresenter-а есть MessagesProvider, вот в нем и происходит настоящая загрузка сообщений.

         У MessagesProvider-а сработает колбэк и цепочка начнет раскручиваться в обратном порядке:

         ChatPresenter дернет метод update... у MessagesListController-a
         Контроллер - update... у MessageListPresenter-а
         Презентер - update... у контроллера MessagesListViewController
         Контроллер - update... у датасурса MessagesListDataSource,
         где уже отрелоудится collectionView.
         */
        self.delegate?.loadOlderMessages()
    }

    func loadNewerMessages() {
        self.delegate?.loadNewerMessages()
    }

    func willDisplayItem(uid: UniqueIdentifierType) {
        self.delegate?.willDisplayItem(uid: uid)

        if uid == "LoadingIndicator" {
            /*
             Снова на пути изнурительного прокидывания.
             Сейчас мы дернем loadOlderMessages у своего делегата - ChatPresenter.
             ChatPresenter это общий знаменатель между контроллером ленты и контроллером поля ввода текста.
             У ChatPresenter-а есть MessagesProvider, вот в нем и происходит настоящая загрузка сообщений.

             У MessagesProvider-а сработает колбэк и цепочка начнет раскручиваться в обратном порядке:

             ChatPresenter дернет метод update... у MessagesListController-a
             Контроллер - update... у MessageListPresenter-а
             Презентер - update... у контроллера MessagesListViewController
             Контроллер - update... у датасурса MessagesListDataSource,
             где уже отрелоудится collectionView.
             */
            self.paginationTriggerThrottler.reset()
        }
    }

    private lazy var paginationTriggerThrottler = Throttler(
        timeout: 2,
        executesPendingAfterCooldown: true
    ) { [weak self] in
        self?.loadOlderMessages()
    }
}
