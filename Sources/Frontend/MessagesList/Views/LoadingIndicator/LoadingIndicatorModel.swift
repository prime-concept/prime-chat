import UIKit

struct LoadingIndicatorModel: MessagesListItemModelProtocol {
    static let chatItemID = "LoadingIndicator"

    var uid: String {
        return "LoadingIndicator"
    }

    var actions = ContentRendererActions()

    var shouldCalculateHeightOnMainThread: Bool {
        return false
    }

    func calculateHeight(collectionViewWidth: CGFloat) -> CGFloat {
        return 44.0
    }

    func configure(cell: UICollectionViewCell) { }

    func isContentEqual(with item: MessagesListItemModelProtocol) -> Bool {
        return true
    }

    static func registerCellWithViewType(collectionView: UICollectionView) {
        collectionView.register(LoadingIndicatorCollectionViewCell.self, forCellWithReuseIdentifier: self.chatItemID)
    }
}
