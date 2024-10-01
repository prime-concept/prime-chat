import UIKit
import SwiftTryCatchSPM

public extension Notification.Name {
    static let messagesListReloadCrashed = Self.init(rawValue: "messagesListReloadCrashed")
}

// Inheritance from NSObject to conform UICollectionView's delegate and data sources
final class MessagesListDataSource: NSObject {
    private static let minMessageAmountForScrollButton = 3
    private static let minOffsetForScrollButton: CGFloat = 300

    private(set) var items: [MessagesListItemModelProtocol] = []

    private weak var viewController: MessagesListViewControllerProtocol?
    private weak var collectionView: UICollectionView?

    private var isFirstTimeUpdate = true

    init(viewController: MessagesListViewControllerProtocol?, collectionView: UICollectionView?) {
        self.viewController = viewController
        self.collectionView = collectionView
        self.collectionView?.alpha = 0
    }
    
    func openContent(for messageGuid: String, completion: MessageContentOpeningCompletion?) {
        let item = self.items.first { $0.uid.contains(messageGuid) } as? MessageModel

        guard let item, collectionView != nil else {
            return
        }

        let completion = completion ?? {}
        item.actions.openContent?(completion)
    }

    func update(
        with newItems: [MessagesListItemModelProtocol],
        completion: (() -> Void)? = nil
    ) {
        assert(Thread.isMainThread)

        let oldItems = self.items
        self.items = newItems

        let hadSomeMessages = oldItems.filter { $0.uid != "LoadingIndicator" }.count > 0
        let receivedSomeMessages = newItems.filter { $0.uid != "LoadingIndicator" }.count > 0

        let diff = DiffCalculator.diff(old: oldItems, new: newItems)

        print("OLD \(oldItems.count), NEW \(newItems.count), DIFF: \(diff)")

        log(
            sender: self,
            """
            [MessagesListDataSource] WILL DISPLAY \(newItems.count) \
            ITEMS, DIFF: INSERTED \(diff.inserted) UPDATED: \(diff.updated) \
            MOVED: \(diff.moved) DELETED: \(diff.deleted)
            """
        )

        let shouldScrollToUnread = !self.didScrollToNearestUnreadMessage && self.firstUnreadMessageIndex != nil
        var shouldScrollToListEnd = hadSomeMessages && diff.inserted.contains(0)

        self.reloadCollectionView(with: diff) { [self] in
            if shouldScrollToUnread {
                scrollToNearestUnreadMessage()
            } else if shouldScrollToListEnd {
                // Вот тут возможно надо не скроллить, а показывать плашку Новые сообщения
                scrollToListEnd(animated: true)
            }

            self.restoreCollectionViewAlpha()

            completion?()
        }
    }

    private func handleCollectionView(crash exception: NSException?) {
        let description = exception?.description ?? ""
        log(sender: self, "[MessagesListDataSource] TRY CATCH BATCH RELOAD EXCEPTION \(description)")
        NotificationCenter.default.post(name: .messagesListReloadCrashed, object: nil)
    }

    private func reloadCollectionView(
        with diff: DiffCalculator.CollectionDiff,
        completion: @escaping () -> Void
    ) {
        guard let collectionView = self.collectionView else {
            completion()
            return
        }

        let deleteIndexPaths = diff.deleted.map { IndexPath(item: $0, section: 0) }
        let insertIndexPaths = diff.inserted.map { IndexPath(item: $0, section: 0) }
        let updateIndexPaths = diff.updated.map { IndexPath(item: $0, section: 0) }

        let moveIndexPaths: [(IndexPath, IndexPath)] = diff.moved.map {
            (IndexPath(item: $0.0, section: 0), IndexPath(item: $0.1, section: 0))
        }

        if deleteIndexPaths.isEmpty, insertIndexPaths.isEmpty, moveIndexPaths.isEmpty {
            collectionView.alpha = 1.0
        }

        log(sender: self, "[MessagesListDataSource] WILL _PERFORM_BATCH_UPDATES_: \(diff)")

        let updates = { [weak self] in
            guard let self else { return }

            collectionView.deleteItems(at: deleteIndexPaths)
            collectionView.insertItems(at: insertIndexPaths)

            moveIndexPaths.forEach {
                collectionView.moveItem(at: $0.0, to: $0.1)
            }

            collectionView.reloadItems(at: updateIndexPaths)
        }
 
        SwiftTryCatch.try({ [weak self] in
            guard let self else { return }

            collectionView.performBatchUpdates(updates) { _ in
                completion()
            }
        }, catch: { exception in
            self.handleCollectionView(crash: exception)
        }, finally: {})
    }

    private func restoreCollectionViewAlpha() {
        guard let collectionView = self.collectionView else {
            return
        }

        let duration = collectionView.alpha == 0 ? 0.25 : 0
        UIView.animate(withDuration: duration) {
            collectionView.alpha = 1.0
        }
    }

    /// Updates the `collectionView` in a way it fully shows the last cell while respecting any additional insets.
    private func scrollToListEnd(animated: Bool) {
        guard let collectionView else {
            assertionFailure("[MessagesListDataSource] collectionView is nil")
            return
        }
        
        let offset = CGPoint(x: 0, y: -collectionView.contentInset.top)
        collectionView.setContentOffset(offset, animated: animated)
    }

    private var didScrollToNearestUnreadMessage = false

    private var firstUnreadMessageIndex: Int? {
        // По сути, чат перевернут
        self.items.lastIndex { model in
            let meta = (model as? MessageModel)?.meta
            return meta?.isUnread == true
        }
    }

    private func scrollToNearestUnreadMessage() {
        if self.didScrollToNearestUnreadMessage {
            return
        }

        guard let row = firstUnreadMessageIndex else {
            return
        }
        
        let indexPath = IndexPath(row: row, section: 0)

        self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
        self.didScrollToNearestUnreadMessage = true
    }

    // MARK: - Private

    private func assertionCollectionView(givenCollectionView: UICollectionView) {
        assert(givenCollectionView == self.collectionView, "Data source should be initialized with same collectionview")
    }

    private func triggerPaginationIfNeeded(collectionView: UICollectionView, indexPath: IndexPath) {
        let itemsCount = self.collectionView?.numberOfItems(inSection: 0) ?? self.items.count

        if indexPath.item >= itemsCount - 1 - 5 {
            /*
             Здесь начинается самая долгая цепочка прокидывания.
             Сперва мы дернем loadOlderMessages у вью-контроллера - MessagesListViewController.
             Он дернет loadOlderMessages у своего презентера - MessagesListPresenter.
             Презентер дернет loadOlderMessages у своего делегата - ChatPresenter.
             ChatPresenter это общий знаменатель между контроллером ленты и контроллером поля ввода текста.
             У ChatPresenter-а есть MessagesProvider, вот в нем и происходит настоящая загрузка сообщений.
             У MessagesProvider-а сработает колбэк и цепочка начнет раскручиваться в обратном порядке:

             ChatPresenter дернет метод update... у MessagesListController-a
             Контроллер - update... у MessageListPresenter-а
             Презентер - update... у контроллера MessagesListViewController
             Контроллер - update... у датасурса (этот файл)
             где уже отрелоудится collectionView.
             */
            self.viewController?.loadOlderMessages()
        }
    }

    private func showScrollToBottomButtonIfNeeded(collectionViewWidth: CGFloat, contentOffset: CGFloat) {
        if self.items.isEmpty || self.items.count < Self.minMessageAmountForScrollButton {
            return
        }
        if contentOffset > Self.minOffsetForScrollButton {
            self.viewController?.updateScrollToBottomButton(isVisible: true)
            return
        }

        let triggerHeight = self.items[0..<Self.minMessageAmountForScrollButton].map {
            $0.calculateHeight(collectionViewWidth: collectionViewWidth)
        }.reduce(0, +)

        self.viewController?.updateScrollToBottomButton(isVisible: contentOffset > triggerHeight)
    }

    private func updateFloatingDate(collectionView: UICollectionView) {
        let items = collectionView
            .indexPathsForVisibleItems
            .sorted(by: { $0.item > $1.item })
            .compactMap { self.items[safe: $0.item ] }

        let messageDates: [String] = items.compactMap { item in
            if let message = item as? MessageModel {
                return message.meta.date
            }
            return nil
        }

        let separatorDates: [String] = items.compactMap { item in
            if let separator = item as? TimeSeparatorModel {
                return separator.date
            }
            return nil
        }

        if let date = messageDates.first {
            if separatorDates.contains(date) {
                self.viewController?.updateFloatingDateSeparator(isVisible: false, animated: true)
            } else {
                self.viewController?.updateFloatingDateSeparator(date: date)
            }
        }
    }
}

extension MessagesListDataSource: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.assertionCollectionView(givenCollectionView: collectionView)
        return self.items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        self.assertionCollectionView(givenCollectionView: collectionView)

        guard let item = self.items[safe: indexPath.item] else {
            // TODO: Сделать настоящий фикс, а не просто игнорирование рассинхрона данных и UI
            log(
                sender: self,
                """
                [MessagesListDataSource] FATAL ERROR Inconsistent state: \
                unable to get item for given index path \(indexPath)
                """
            )
            return UICollectionViewCell()
        }

        let reuseIdentifier = type(of: item).chatItemID
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)

        UIView.performWithoutAnimation {
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
            item.configure(cell: cell)
        }

        return cell
    }

    private func addCounter(to cell: UICollectionViewCell, at indexPath: IndexPath) {
        if let tag = cell.contentView.viewWithTag(1) {
            tag.removeFromSuperview()
        }
        let tag = UILabel(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        tag.textColor = .red
        tag.text = "\(indexPath.row)"
        tag.tag = 1

        cell.contentView.addSubview(tag)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        self.assertionCollectionView(givenCollectionView: collectionView)
        self.updateFloatingDate(collectionView: collectionView)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        self.assertionCollectionView(givenCollectionView: collectionView)

        guard let item = self.items[safe: indexPath.item] else {
            // TODO: Сделать настоящий фикс, а не просто игнорирование рассинхрона данных и UI
            log(
                sender: self,
                """
                [MessagesListDataSource] FATAL ERROR Inconsistent state: \
                unable to get item for given index path \(indexPath)
                """
            )
            return
        }

        self.viewController?.willDisplayItem(uid: item.uid)
        self.triggerPaginationIfNeeded(collectionView: collectionView, indexPath: indexPath)

        self.updateFloatingDate(collectionView: collectionView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.viewController?.updateFloatingDateSeparator(isVisible: false)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.viewController?.updateFloatingDateSeparator(isVisible: false)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.viewController?.updateFloatingDateSeparator(isVisible: decelerate)
    }
}

final class BlockEnqueuer {
    typealias RunNext = () -> Void

    private let blocksAccessLock = NSRecursiveLock()
    
    private var blocks = [(@escaping RunNext) -> Void]()

    private(set) var queueLength: Int?
    private(set) var throttle: TimeInterval?

    private var mayEnqueueAnotherBlock = true

    init(queueLength: Int? = nil, throttle: TimeInterval? = nil) {
        self.queueLength = queueLength
        self.throttle = throttle
    }

    func enqueue(_ block: @escaping (@escaping RunNext) -> Void) {
        self.blocksAccessLock.locked {
            guard self.mayEnqueueAnotherBlock else {
                return
            }

            if let throttle = self.throttle {
                self.mayEnqueueAnotherBlock = false
                delay(throttle) { [weak self] in
                    self?.mayEnqueueAnotherBlock = true
                }
            }

            if let queueLength = self.queueLength, self.blocks.count >= queueLength {
                return
            }

            self.blocks.append { runNext in
                block(runNext)
            }

            if self.blocks.count == 1 {
                block(self.runNext)
            }
        }
    }

    private func runNext() {
        self.blocksAccessLock.locked {
            guard !self.blocks.isEmpty else {
                return
            }
            
            let block = self.blocks.first
            self.blocks = Array(self.blocks.dropFirst())
            block?(self.runNext)
        }
    }
}
