import UIKit
import Photos

protocol PhotoAlbumsListDataSourceOutputProtocol: AnyObject {
    func presentAssets(title: String, assets: [PHAsset])
    func requestTableViewReload()
    func closeModule()
    func showDeniedPermissionAlert()
}

final class PhotoAlbumsListDataSource: NSObject {
    private var albums: [PhotoAlbum] = [] {
        didSet {
            DispatchQueue.main.async {
                self.output?.requestTableViewReload()
            }
        }
    }

    private var collections: [PHAssetCollection] = []
    private var isAuthorized = false

    private weak var output: PhotoAlbumsListDataSourceOutputProtocol?

    init(output: PhotoAlbumsListDataSourceOutputProtocol?) {
        self.output = output

        super.init()

        self.checkAuthorizationStatus { [weak self] success in
            self?.isAuthorized = success
            self?.loadAlbums()
        }
    }

    // MARK: - Private API

    private func checkAuthorizationStatus(completion: @escaping ((Bool) -> Void)) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            completion(true)
        } else if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                let isAuthorized = status == .authorized

                if !isAuthorized {
                    self?.output?.closeModule()
                }
                completion(isAuthorized)
            }
        } else {
            self.output?.showDeniedPermissionAlert()
            completion(false)
        }
    }

    private func loadAlbums() {
        guard self.isAuthorized else {
            return
        }

        let collections = self.loadAllAssetCollections()
        let albums = collections.map { self.makeAlbum(from: $0) }

        self.collections = collections
        self.albums = albums
    }

    private func loadAllAssetCollections() -> [PHAssetCollection] {
        var allCollections: [PHAssetCollection] = []

        let userCreatedCollections = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        userCreatedCollections.enumerateObjects { (collection, _, _) in
            guard let assetCollection = collection as? PHAssetCollection else {
                return
            }
            allCollections.append(assetCollection)
        }

        let smartAlbumCollections = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
        smartAlbumCollections.enumerateObjects { (collection, _, _) in
            allCollections.append(collection)
        }

        let albumsAndCount: [(PHAssetCollection, Int)] = allCollections.compactMap { album in
            let photosCount = PHAsset.fetchAssets(in: album, options: nil).count
            return photosCount == 0 ? nil : (album, photosCount)
        }

        return albumsAndCount
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    private func makeAlbum(from collection: PHAssetCollection) -> PhotoAlbum {
        let assets = PHAsset.fetchAssets(in: collection, options: nil)

        return PhotoAlbum(
            thumbnailAsset: assets.lastObject,
            title: collection.localizedTitle ?? "",
            count: assets.count
        )
    }

    private func makeAssets(from collection: PHAssetCollection) -> [PHAsset] {
        var assets: [PHAsset] = []
        PHAsset.fetchAssets(in: collection, options: nil).enumerateObjects { (asset, _, _) in
            assets.append(asset)
        }

        return assets.reversed()
    }
}

extension PhotoAlbumsListDataSource: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let collection = self.collections[safe: indexPath.row] else {
            return
        }

        self.output?.presentAssets(
            title: collection.localizedTitle ?? "",
            assets: self.makeAssets(from: collection)
        )
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return PhotoAlbumTableViewCell.height
    }
}

extension PhotoAlbumsListDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.albums.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PhotoAlbumTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? PhotoAlbumTableViewCell else {
            fatalError("Incorrect cell type")
        }
        if let album = self.albums[safe: indexPath.row] {
            cell.configure(with: album)
        }
        return cell
    }
}
