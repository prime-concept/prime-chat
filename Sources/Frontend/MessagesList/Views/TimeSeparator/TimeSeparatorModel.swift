import UIKit

struct TimeSeparatorModel: MessagesListItemModelProtocol {
    static let chatItemID = "TimeSeparator"

    let uid: String
    let date: String

    var actions = ContentRendererActions()

    var shouldCalculateHeightOnMainThread: Bool {
        return false
    }

    init(uid: String, date: String) {
        self.uid = uid
        self.date = date
    }

    func calculateHeight(collectionViewWidth: CGFloat) -> CGFloat {
        return TimeSeparatorCollectionViewCell.height
    }

    func configure(cell: UICollectionViewCell) {
        guard let cell = cell as? TimeSeparatorCollectionViewCell else {
            return
        }

        cell.text = self.date
    }

    func isContentEqual(with item: MessagesListItemModelProtocol) -> Bool {
        return true
    }

    static func registerCellWithViewType(collectionView: UICollectionView) {
        collectionView.register(TimeSeparatorCollectionViewCell.self, forCellWithReuseIdentifier: self.chatItemID)
    }

    var openContent: ((@escaping MessageContentOpeningCompletion) -> Void)? {
        nil
    }
}
