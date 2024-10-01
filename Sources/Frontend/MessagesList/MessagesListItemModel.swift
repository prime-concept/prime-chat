import UIKit

/// Type of unique identifier
public typealias UniqueIdentifierType = String

/// Representation of each chat item (time separators, bubbles, etc)
public protocol MessagesListItemModelProtocol {
    static var chatItemID: String { get }

    var uid: UniqueIdentifierType { get }

    var actions: ContentRendererActions { get }

    var shouldCalculateHeightOnMainThread: Bool { get }

    func calculateHeight(collectionViewWidth: CGFloat) -> CGFloat

    func configure(cell: UICollectionViewCell)

    func isContentEqual(with item: MessagesListItemModelProtocol) -> Bool

    static func registerCellWithViewType(collectionView: UICollectionView)
}
