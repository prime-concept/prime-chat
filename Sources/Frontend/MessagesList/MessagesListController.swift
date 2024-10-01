import UIKit

public protocol MessagesListUI: AnyObject {
    func adjustContentInsets(top: CGFloat, bottom: CGFloat)
    func setOverlay(_ view: UIView)
}

public protocol MessagesList: MessagesListUI {
    func update(with items: [MessagesListItemModelProtocol])
    func addBottomView(_ view: UIView)
    var bottomViewExists: Bool { get }
    var viewController: UIViewController { get }
}

protocol MessagesListViewControllerProtocol: UIViewController, MessagesList, MessagesListUI {
    func loadOlderMessages()
    func willDisplayItem(uid: UniqueIdentifierType)
    
    func update(with items: [MessagesListItemModelProtocol])
    func updateFloatingDateSeparator(isVisible: Bool)
    func updateFloatingDateSeparator(isVisible: Bool, animated: Bool)
    func updateFloatingDateSeparator(date: String)
    func updateScrollToBottomButton(isVisible: Bool)

    func scroll(to messageGuid: String, completion: @escaping (Bool) -> Void)
    func openContent(for messageGuid: String, completion: MessageContentOpeningCompletion?)
    func stopRefreshLoader()
}

final class MessagesListViewController: UIViewController, MessagesListViewControllerProtocol {
    private enum Appearance {
        static let stickySeparatorTopOffset: CGFloat = 9.5
    }
    
    private let presenter: MessagesListPresenterProtocol
    
    private lazy var collectionView = self.makeCollectionView()
    
    private lazy var collectionViewLayout = self.makeCollectionViewLayout()
    
    private lazy var stickySeparatorView: TimeSeparatorView = {
        let view = TimeSeparatorView()
        view.alpha = 0
        return view
    }()

    private lazy var refreshControl = self.makeRefreshControl()
    
    private lazy var scrollToBottomButton = self.makeScrollToBottomButton()
    
    private lazy var dataSource = MessagesListDataSource(viewController: self, collectionView: self.collectionView)

    private lazy var heightCalculator = MessagesListItemsLayoutCalculator()
    private var lastLayoutModel: MessagesListLayoutModel?
    
    private var floatingDateWorkItem: DispatchWorkItem?
    
    private var isPaginationLoadingVisible = false
    
    private var reloadInProgress = false
    
    private let updatesEnqueuer = BlockEnqueuer()
    private let updatesQueue = DispatchQueue(label: "MessagesListUpdatesQueue", qos: .userInitiated)
    
    var bottomViewExists: Bool = false
    
    init(presenter: MessagesListPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupController()

        self.setupAlertIfCrashed()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presenter.didAppear()
    }

    func setup(for contentRendererTypes: [ContentRenderer.Type]) {
        TimeSeparatorModel.registerCellWithViewType(collectionView: self.collectionView)
        LoadingIndicatorModel.registerCellWithViewType(collectionView: self.collectionView)

        for presenterType in contentRendererTypes {
            presenterType.messageModelType.registerCellWithViewType(collectionView: self.collectionView)
        }
    }

    func scroll(to messageGuid: String, completion: @escaping (Bool) -> Void) {
        self.updatesEnqueuer.enqueue { [weak self] runNext in
            guard let self else { return }

            let index = self.dataSource.items.firstIndex { $0.uid.contains(messageGuid) }
            guard let index else {
                completion(false)
                return
            }

            self.collectionView.setNeedsLayout()
            self.collectionView.layoutIfNeeded()

            let indexPath = IndexPath(row: index, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)

            delay(CATransaction.animationDuration()) {
                completion(true)
                runNext()
            }
        }
    }

    func update(with items: [MessagesListItemModelProtocol]) {
        let collectionViewWidth = min(collectionView.bounds.width, UIScreen.main.bounds.width)

        self.updatesEnqueuer.enqueue { [weak self] runNext in
            let update = { [weak self] in
                guard let self = self else { return }

                self.reloadInProgress = true

                log(sender: self, "chat ui: request update, items count = " + String(items.count))

                let updateCompletion = {
                    self.reloadInProgress = false

                    log(sender: self, "chat ui: batch update completed")

                    self.presenter.viewController(self, didUpdateWith: items)
                    self.markAsSeenIfNeeded()
                    
                    runNext()
                }

                self.updateItemsInternal(
                    items: items,
                    collectionViewWidth: collectionViewWidth,
                    completion: updateCompletion
                )
            }

            self?.updatesQueue.async(execute: update)
        }
    }

    private func setupAlertIfCrashed() {
        Notification.onReceive(.messagesListReloadCrashed) { _ in
            let alert = UIAlertController(
                title: "reload.crash.title".localized,
                message: "reload.crash.message".localized,
                preferredStyle: .alert
            )
            
            let action = UIAlertAction(title: "common.ok".localized, style: .default)
            alert.addAction(action)

            self.topmostPresentedOrSelf.present(alert, animated: true)
        }
    }

    private func markAsSeenIfNeeded() {
        let visibleIndices = self.collectionView.indexPathsForVisibleItems.map(\.row)
        if visibleIndices.isEmpty {
            log(sender: self, "1) WILL MARK AS SEEN: NONE, RETURN")
            return
        }

        let min = visibleIndices.min()!
        let max = visibleIndices.max()!

        let items = self.dataSource.items

        guard let items = items[from: min, to: max] else {
            log(sender: self, "2) WILL MARK AS SEEN: NONE, RETURN")
            return
        }

        log(sender: self, "WILL MARK AS SEEN: \(visibleIndices), MIN \(min) MAX \(max), TOTAL \(items.count)")

        items.forEach { item in
            self.willDisplayItem(uid: item.uid)
        }

        log(sender: self, "DID MARK AS SEEN: \(items.map(\.uid))")
    }

    func stopRefreshLoader() {
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
    }

    func adjustContentInsets(top: CGFloat, bottom: CGFloat) {
        self.collectionView.contentInset = UIEdgeInsets(top: bottom, left: 0, bottom: top, right: 0)
        self.collectionView.scrollIndicatorInsets = UIEdgeInsets(top: bottom, left: 0, bottom: top, right: 0)
    }
    
    func addBottomView(_ view: UIView) {
        self.view.addSubview(view)
        view.make(.bottom, .equalToSuperview, -(self.view.safeAreaInsets.bottom + 40))
        view.make(.centerX, .equalToSuperview)
        self.view.bringSubviewToFront(view)
        self.bottomViewExists = true
    }

    // MARK: - Private

    private func updateItemsInternal(
        items: [MessagesListItemModelProtocol],
        collectionViewWidth: CGFloat,
        completion: @escaping () -> Void
    ) {
        assert(!Thread.isMainThread)

        log(sender: self, "chat ui: WILL CALCULATE ITEMS HEIGHT, ITEMS: " + String(items.count))

        self.notifyMessagesLoaded(items)

        // Calculate layout
        let result = self.heightCalculator.calculateHeight(
            for: items,
            collectionViewWidth: collectionViewWidth
        )

        DispatchQueue.main.async {
            log(sender: self, "chat ui: DID CALCULATE ITEMS HEIGHT, ITEMS: " + String(items.count))

            // Store layout
            self.lastLayoutModel = MessagesListLayoutModel.makeModel(
                collectionViewWidth: collectionViewWidth,
                itemsLayoutData: result.map { (height: $0, bottomMargin: 0.0) },
                topOffset: 12,
                bottomOffset: 13
            )

            log(sender: self, "chat ui: WILL ACTUALLY RELOAD COLLECTION VIEW")
            self.dataSource.update(with: items, completion: completion)
        }
    }

    private func notifyMessagesLoaded(_ items: [MessagesListItemModelProtocol]) {
        let guids = items.map(\.uid).map {
            $0.replacingOccurrences(of: "Message_", with: "").lowercased()
        }

        NotificationCenter.default.post(
            name: .chatSDKDidMarkMessagesAsSeen, object: nil, userInfo: ["guids": guids]
        )
    }

    private func setupController() {
        guard let view else { return }

        let collectionView = self.collectionView
        view.addSubview(collectionView)

        collectionView.make(.top, .equal, to: view.safeAreaLayoutGuide)
        collectionView.make(.bottom, .equalToSuperview)
        collectionView.make(.hEdges, .equalToSuperview, priorities: [.defaultHigh, .defaultHigh])
        collectionView.make(.width, .lessThanOrEqual, UIScreen.main.bounds.width, priority: .required)
        collectionView.make(.center, .equalToSuperview)

        collectionView.refreshControl = self.refreshControl

        collectionView.dataSource = self.dataSource
        collectionView.delegate = self.dataSource // да.

        let timeLabel = self.stickySeparatorView
        view.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 11.0, *) {
            timeLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Appearance.stickySeparatorTopOffset
            ).isActive = true
        } else {
            timeLabel.topAnchor.constraint(
                equalTo: view.topAnchor,
                constant: Appearance.stickySeparatorTopOffset
            ).isActive = true
        }
        timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: 25).isActive = true

        let scrollToBottomButton = self.scrollToBottomButton
        view.addSubview(scrollToBottomButton)
        scrollToBottomButton.translatesAutoresizingMaskIntoConstraints = false
        scrollToBottomButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        scrollToBottomButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        self.automaticallyAdjustsScrollViewInsets = false
    }

    private func makeRefreshControl() -> UIRefreshControl {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.onRefreshAction), for: .valueChanged)
        return refreshControl
    }

    private func makeCollectionView() -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.makeCollectionViewLayout())

        collectionView.alwaysBounceVertical = true
        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .interactive
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.transform = CGAffineTransform(scaleX: 1, y: -1)

        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }

        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        collectionView.isPrefetchingEnabled = false

        collectionView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(self.onCollectionViewTap)
            )
        )

        return collectionView
    }
    
    private func makeCollectionViewLayout() -> MessagesListLayout {
        return MessagesListLayout { [weak self] in
            self?.lastLayoutModel
        }
    }

    private func makeScrollToBottomButton() -> ScrollToBottomButtonView {
        let view = ScrollToBottomButtonView()
        view.alpha = 0
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onScrollToBottomClick)))
        return view
    }

    @objc
    private func onRefreshAction() {
        self.presenter.loadNewerMessages()
    }

    @objc
    private func onScrollToBottomClick() {
        self.scrollToBottom()
    }

    private func scrollToBottom() {
        let collectionView = self.collectionView
        guard collectionView.numberOfItems(inSection: 0) > 0 else {
            return
        }
        let bottomItem = IndexPath(row: 0, section: 0)
        collectionView.scrollToItem(at: bottomItem, at: .bottom, animated: true)
    }

    @objc
    private func onCollectionViewTap() {
        self.view.superview?.endEditing(true)
    }
}

extension MessagesListViewController {
    func loadOlderMessages() {
        /*
         Мы на пути изнурительного прокидывания.
         Сейчас мы дернем loadOlderMessages у своего презентера - MessagesListPresenter.
         Презентер дернет loadOlderMessages у своего делегата - ChatPresenter.
         ChatPresenter это общий знаменатель между контроллером ленты и контроллером поля ввода текста.
         У ChatPresenter-а есть MessagesProvider, вот в нем и происходит настоящая загрузка сообщений.

         У MessagesProvider-а сработает колбэк и цепочка начнет раскручиваться в обратном порядке:

         ChatPresenter дернет метод update... у MessagesListController-a
         Контроллер - update... у MessageListPresenter-а
         Презентер - update... у контроллера MessagesListViewController
         Контроллер - update... у датасурса MessagesListDataSource,
         где уже отрелоудится collectionView.
         */
        self.presenter.loadOlderMessages()
    }

    func willDisplayItem(uid: UniqueIdentifierType) {
        if !self.reloadInProgress {
            self.presenter.willDisplayItem(uid: uid)
        }
    }

    func updateFloatingDateSeparator(date: String) {
        self.stickySeparatorView.text = date
    }

    func updateFloatingDateSeparator(isVisible: Bool) {
        self.updateFloatingDateSeparator(isVisible: isVisible, animated: true)
    }

    func updateFloatingDateSeparator(isVisible: Bool, animated: Bool) {
        guard self.stickySeparatorView.text != nil else {
            return
        }

        // swiftlint:disable all
        let floatingDateWorkItem = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: animated ? 0.25 : 0) {
                self?.stickySeparatorView.alpha = isVisible ? 1 : 0
            }
        }
        // swiftlint:enable all

        self.floatingDateWorkItem?.cancel()
        self.floatingDateWorkItem = floatingDateWorkItem

        let delay = animated ? (isVisible ? 0.0 : 0.5) : 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: floatingDateWorkItem)
    }

    func updateScrollToBottomButton(isVisible: Bool) {
        UIView.animate(
            withDuration: 0.25,
            animations: { [weak self] in
                self?.scrollToBottomButton.alpha = isVisible ? 1 : 0
            }
        )
    }

    func openContent(for messageGuid: String, completion: MessageContentOpeningCompletion?) {
        self.dataSource.openContent(for: messageGuid, completion: completion)
    }
}

// MARK: - MessagesListItemsLayoutCalculator

private final class MessagesListItemsLayoutCalculator {
    private static let queue = DispatchQueue(label: "MessagesListItemsLayoutCalculator", qos: .userInitiated)

    func calculateHeight(
        for models: [MessagesListItemModelProtocol],
        collectionViewWidth: CGFloat
    ) -> [CGFloat] {
        var results: [CGFloat] = Array(repeating: 0.0, count: models.count)
        var itemsForBackgroundRendering: [Int] = []

        for (index, model) in models.enumerated() {
            if model.shouldCalculateHeightOnMainThread {
                DispatchQueue.main.async {
                    let height = model.calculateHeight(collectionViewWidth: collectionViewWidth)
                    results[index] = height
                }
            } else {
                itemsForBackgroundRendering.append(index)
            }
        }

        log(sender: self,
            "chat ui: layout calculating: " +
            "main = \(models.count - itemsForBackgroundRendering.count), bg = \(itemsForBackgroundRendering.count)"
        )

        if itemsForBackgroundRendering.isEmpty {
            return results
        }

        for index in itemsForBackgroundRendering {
            let model = models[index]
            let height = model.calculateHeight(collectionViewWidth: collectionViewWidth)
            results[index] = height
        }

        return results
    }
}

extension MessagesListViewController: MessagesList {
    var viewController: UIViewController {
        return self
    }

    func setOverlay(_ view: UIView) {
        guard let chatView = self.view else {
            fatalError("There MUST be MessagesListViewController's view before setting overlay")
        }
        chatView.addSubview(view)
        view.topAnchor.constraint(equalTo: chatView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: chatView.leadingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: chatView.bottomAnchor).isActive = true
        view.rightAnchor.constraint(equalTo: chatView.rightAnchor).isActive = true
    }
}

extension Array {
    subscript(from start: Int, to end: Int) -> [Element]? {
        guard self.count > start, self.count > end else {
            return nil
        }

        return Array(self[ClosedRange(uncheckedBounds: (lower: start, upper: end))])
    }
}
