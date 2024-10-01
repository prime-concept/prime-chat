import UIKit

struct MessagesListLayoutModel {
    typealias LayoutData = (height: CGFloat, bottomMargin: CGFloat)

    let contentSize: CGSize
    let layoutAttributes: [UICollectionViewLayoutAttributes]
    let width: CGFloat

    static func makeModel(
        collectionViewWidth: CGFloat,
        itemsLayoutData: [LayoutData],
        topOffset: CGFloat,
        bottomOffset: CGFloat
    ) -> MessagesListLayoutModel {
        var layoutAttributes: [UICollectionViewLayoutAttributes] = []

        var verticalOffset: CGFloat = topOffset
        for (index, layoutData) in itemsLayoutData.enumerated() {
            let indexPath = IndexPath(item: index, section: 0)
            let (height, bottomMargin) = layoutData

            let itemSize = CGSize(width: collectionViewWidth, height: height)
            let frame = CGRect(origin: CGPoint(x: 0, y: verticalOffset), size: itemSize)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

            attributes.frame = frame

            layoutAttributes.append(attributes)
            verticalOffset += itemSize.height
            verticalOffset += bottomMargin
        }
        verticalOffset += bottomOffset

        return MessagesListLayoutModel(
            contentSize: CGSize(width: collectionViewWidth, height: verticalOffset),
            layoutAttributes: layoutAttributes,
            width: collectionViewWidth
        )
    }

    fileprivate static func makeEmptyModel() -> MessagesListLayoutModel {
        return MessagesListLayoutModel(
            contentSize: .zero,
            layoutAttributes: [],
            width: 0
        )
    }
}

final class MessagesListLayout: UICollectionViewLayout {
    typealias LayoutModelCreator = () -> MessagesListLayoutModel?

    private var layoutModel = MessagesListLayoutModel.makeEmptyModel()
    private let layoutModelCreator: LayoutModelCreator

    private var layoutNeedsUpdate = true

    init(layoutModelCreator: @escaping LayoutModelCreator) {
        self.layoutModelCreator = layoutModelCreator
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Optimization from Chatto: force update after invalidate
    override func invalidateLayout() {
        super.invalidateLayout()
        self.layoutNeedsUpdate = true
    }

    override func prepare() {
        super.prepare()

        guard self.layoutNeedsUpdate else {
            return
        }

        guard let layoutModel = self.layoutModelCreator() else {
            return
        }

        var oldLayoutModel: MessagesListLayoutModel? = self.layoutModel
        self.layoutModel = layoutModel

        self.layoutNeedsUpdate = false

        // Optimization from Chatto: dealloc on background thread
        DispatchQueue.global(qos: .default).async {
            if oldLayoutModel != nil {
                oldLayoutModel = nil
            }
        }
    }

    override var collectionViewContentSize: CGSize {
        return self.layoutModel.contentSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var attributesArray: [UICollectionViewLayoutAttributes] = []
        let layoutModel = self.layoutModel

        guard let firstMatchIndex = layoutModel.layoutAttributes.binarySearch(
            predicate: { attribute in
                if attribute.frame.intersects(rect) {
                    return .orderedSame
                }
                if attribute.frame.minY > rect.maxY {
                    return .orderedDescending
                }
                return .orderedAscending
            }
        ) else {
            return attributesArray
        }

        for attributes in layoutModel.layoutAttributes[..<firstMatchIndex].reversed() {
            guard attributes.frame.maxY >= rect.minY else {
                break
            }
            attributesArray.append(attributes)
        }

        for attributes in layoutModel.layoutAttributes[firstMatchIndex...] {
            guard attributes.frame.minY <= rect.maxY else {
                break
            }
            attributesArray.append(attributes)
        }

        return attributesArray
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let layoutModel = self.layoutModel

        guard indexPath.section == 0 else {
            return nil
        }

        if indexPath.item < layoutModel.layoutAttributes.count {
            return layoutModel.layoutAttributes[indexPath.item]
        }
        
        return nil
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return self.layoutModel.width != newBounds.width
    }
}

private extension Array {
    func binarySearch(predicate: (Element) -> ComparisonResult) -> Index? {
        var lowerBound = self.startIndex
        var upperBound = self.endIndex

        while lowerBound < upperBound {
            let midIndex = lowerBound + (upperBound - lowerBound) / 2
            if predicate(self[midIndex]) == .orderedSame {
                return midIndex
            } else if predicate(self[midIndex]) == .orderedAscending {
                lowerBound = midIndex + 1
            } else {
                upperBound = midIndex
            }
        }
        return nil
    }
}
