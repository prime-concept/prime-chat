import UIKit

/// Message reply model meta information (senderName, content)
public struct MessageReplyModelMeta: Equatable {
    let senderName: String
    let content: String
}

/// Representation of chat message item
public protocol MessageModel: MessagesListItemModelProtocol {
    var meta: MessageContainerModelMeta { get }

    /// Content version: if this values changed then content also changed
    var contentControlValue: Int { get }
}

/// Message container model meta information (uid, time, status)
public struct MessageContainerModelMeta {
    let time: String
    let date: String
    let status: Status
    let messenger: MessageSource

    var isUnread: Bool {
        self.author == .anotherUser && self.status == .unseen
    }

    public let author: Author
    public let isNextMessageOfSameUser: Bool
    public let replyMeta: MessageReplyModelMeta?

    public var isFailed: Bool {
        self.status == .failed
    }

    enum Status: Equatable {
        case unseen
        case seen
        case sending
        case notSent
        case failed
    }

    public enum Author: Equatable {
        case me
        case anotherUser
    }
}

/// Representation of message with content in channel.
/// It contains `contentConfigurator` – closure for view configuration and
/// `heightCalculator` – closure for height changes reporting.
public final class MessageContainerModel<ViewType: MessageContentViewProtocol>: MessageModel {
    public static var chatItemID: String {
        return "MessageContainer_\(ViewType.self.description())"
    }

    public let uid: String

    // MARK: - Meta info

    public let meta: MessageContainerModelMeta

    public let contentControlValue: Int

    public let shouldCalculateHeightOnMainThread: Bool

    public let actions: ContentRendererActions

    // MARK: - Content info

    let contentConfigurator: (ViewType) -> Void

    private let heightCalculator: (CGFloat, CGSize) -> CGFloat

    public init(
        uid: String,
        meta: MessageContainerModelMeta,
        contentControlValue: Int,
        shouldCalculateHeightOnMainThread: Bool,
        actions: ContentRendererActions,
        contentConfigurator: @escaping (ViewType) -> Void,
        heightCalculator: @escaping (CGFloat, CGSize) -> CGFloat
    ) {
        self.uid = uid
        self.meta = meta
        self.contentControlValue = contentControlValue
        self.shouldCalculateHeightOnMainThread = shouldCalculateHeightOnMainThread
        self.actions = actions

        self.contentConfigurator = contentConfigurator
        self.heightCalculator = heightCalculator
    }

    public func calculateHeight(collectionViewWidth: CGFloat) -> CGFloat {
        let messageContainerWidth = MessageContainerCollectionViewCell<ViewType>.widthForContent(
            cellWidth: collectionViewWidth,
            meta: self.meta
        )

        let infoViewAreaSize = MessageInfoView.size(for: self.meta)
        let infoViewAreaSizeWithPadding = CGSize(
            width: infoViewAreaSize.width + MessageContainerCellLayout.infoViewPaddingInsets.right,
            height: infoViewAreaSize.height + MessageContainerCellLayout.infoViewPaddingInsets.bottom
        )
        let replyHeight = self.meta.replyMeta == nil ? 0 : MessageContainerCellLayout.replyHeight
        let contentHeight = self.heightCalculator(messageContainerWidth, infoViewAreaSizeWithPadding)
        return MessageContainerCollectionViewCell<ViewType>.calculateHeight(with: contentHeight + replyHeight)
    }

    public func configure(cell: UICollectionViewCell) {
        // @v.kiryukhin: compiler bug, see https://bugs.swift.org/browse/SR-5252
        guard let cell = cell as? MessageContainerCollectionViewCell<ViewType> else {
            return
        }

        cell.configure(with: self)
    }

    public static func registerCellWithViewType(collectionView: UICollectionView) {
        collectionView.register(
            MessageContainerCollectionViewCell<ViewType>.self,
            forCellWithReuseIdentifier: self.chatItemID
        )
    }

    public func isContentEqual(with item: MessagesListItemModelProtocol) -> Bool {
        guard let item = item as? MessageContainerModel<ViewType> else {
            return false
        }

        return self.meta.author == item.meta.author
        && self.meta.status == item.meta.status
        && self.meta.time == item.meta.time
        && self.contentControlValue == item.contentControlValue
        && self.meta.isNextMessageOfSameUser == item.meta.isNextMessageOfSameUser
    }
}
