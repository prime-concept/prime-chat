import UIKit
import Photos

public enum MediaAssetType {
    case photo
    case video
}

public struct MediaAsset {
    let name: String
    let type: MediaAssetType
    let data: Data
    let image: UIImage
    let duration: Double?
}

protocol PhotoAlbumDataSourceOutputProtocol: AnyObject {
    func requestCollectionViewReload()
    func mediaAssetItemSize(width: CGFloat) -> CGSize
    func didSelectMediaAssets(count: Int)
}

final class PhotoAlbumDataSource: NSObject {
    private var assets: [PHAsset] = [] {
        didSet {
            DispatchQueue.main.async {
                self.output?.requestCollectionViewReload()
            }
        }
    }

    private weak var output: PhotoAlbumDataSourceOutputProtocol?
    private weak var collectionView: UICollectionView?

    private var selectedIndexes: [IndexPath] = []

    init(output: PhotoAlbumDataSourceOutputProtocol?) {
        self.output = output
    }

    // MARK: - Public API

    func update(with assets: [PHAsset]) {
        self.assets = assets
    }

    func getSelectedMediaAssets(completion: @escaping (([MediaAsset]) -> Void)) {
        self.makeMediaAssets(
            from: self.selectedIndexes,
            assets: self.assets,
            completion: completion
        )
    }

    // MARK: - Private API

    private func updateSelectedIndexes(collectionView: UICollectionView, indexPath: IndexPath) {
        let selectedIndexes = collectionView.indexPathsForSelectedItems ?? []
        self.selectedIndexes = selectedIndexes

        self.output?.didSelectMediaAssets(count: selectedIndexes.count)
    }

    private func makeMediaAssets(
        from indexes: [IndexPath],
        assets: [PHAsset],
        completion: @escaping (([MediaAsset]) -> Void)
    ) {
        if indexes.isEmpty {
            completion([])
            return
        }

        var mediaAssetsDict: [Int: MediaAsset] = [:]
        let group = DispatchGroup()
        let selectedAssets = indexes.compactMap { assets[safe: $0.item] }

        for (index, asset) in selectedAssets.enumerated() {
            group.enter()
            asset.getMediaAssetAsDataAsync { (image, data, duration) in
                let data = data ?? Data()
                let image = image ?? UIImage()
                group.leave()
                let mediaAsset = MediaAsset(
                    name: asset.fileName,
                    type: asset.mediaAssetType,
                    data: data,
                    image: image,
                    duration: duration
                )
                mediaAssetsDict[index] = mediaAsset
            }
        }

        group.notify(queue: .main) {
            let mediaAssets = mediaAssetsDict.sorted { $0.key < $1.key }.map { $0.value }
            completion(mediaAssets)
        }
    }
}

extension PhotoAlbumDataSource: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        self.selectedIndexes.append(indexPath)

        self.output?.didSelectMediaAssets(count: self.selectedIndexes.count)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didDeselectItemAt indexPath: IndexPath
    ) {
        guard let index = self.selectedIndexes.firstIndex(of: indexPath) else {
            return
        }

        self.selectedIndexes.remove(at: index)
        self.output?.didSelectMediaAssets(count: self.selectedIndexes.count)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = min(UIScreen.main.bounds.width, collectionView.bounds.width)
        return self.output?.mediaAssetItemSize(width: width) ?? .zero
    }
}

extension PhotoAlbumDataSource: UICollectionViewDataSource {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return self.assets.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let asset = self.assets[safe: indexPath.item] else {
            fatalError("Asset not exists")
        }
        let model = PhotoViewModel(asset: asset)

        switch asset.mediaAssetType {
        case .photo:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PhotoItemCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? PhotoItemCollectionViewCell else {
                fatalError("Incorrect cell type")
            }
            cell.configure(with: model)
            return cell
        case .video:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: VideoItemCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? VideoItemCollectionViewCell else {
                fatalError("Incorrect cell type")
            }
            cell.configure(with: model)
            return cell
        }
    }
}
