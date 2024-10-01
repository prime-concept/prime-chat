import UIKit
import Photos
import CoreMedia

extension PHAsset {
    var fileName: String {
        var fileName = PHAssetResource.assetResources(for: self).first?.originalFilename
        if fileName == nil {
            fileName = self.value(forKey: "filename") as? String
        }
        return fileName ?? ""
    }

    var mediaAssetType: MediaAssetType {
        switch self.mediaType {
        case .image:
            return .photo
        case .video:
            return .video
        case .unknown, .audio:
            fatalError("Not supported")
        @unknown default:
            return .photo
        }
    }

    func getAssetAsImage(size: CGSize = PHImageManagerMaximumSize, completion: ((UIImage?) -> Void)?) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.resizeMode = .exact
        manager.requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: options) { (image, _) in
            completion?(image)
        }
    }

    func getAssetAsVideoImagePreview(
        size: CGSize = PHImageManagerMaximumSize,
        completion: ((UIImage?, Double) -> Void)?
    ) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.resizeMode = .exact
        manager.requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: options) { (image, _) in
            completion?(image, self.duration)
        }
    }

    func getMediaAssetAsDataAsync(
        completion: @escaping ((UIImage?, Data?, Double?) -> Void)
    ) {
        if self.mediaAssetType == .photo {
            self.getPhotoAssetAsImageAsync(completion: completion)
        } else {
            self.getVideoAssetAsDataAsync(completion: completion)
        }
    }

    // MARK: - Private

    private func getPhotoAssetAsImageAsync(
        completion: @escaping ((UIImage?, Data?, Double?) -> Void)
    ) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        let size = PHImageManagerMaximumSize

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }

            options.isNetworkAccessAllowed = false
            options.isSynchronous = true
            manager.requestImage(for: self, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
                let data = image.flatMap { $0.jpegData(compressionQuality: 0.6) }
                DispatchQueue.main.async {
                    completion(image, data, nil)
                }
            }
        }
    }

    private func getVideoAssetAsDataAsync(
        completion: @escaping ((UIImage?, Data?, Double?) -> Void)
    ) {
        let manager = PHImageManager.default()
        let options = PHVideoRequestOptions()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }

            options.version = .original
            options.deliveryMode = .highQualityFormat

            manager.requestAVAsset(forVideo: self, options: options) { (asset, _, _) in
                if let urlAsset = asset as? AVURLAsset {
                    let data = try? Data(contentsOf: urlAsset.url)
                    urlAsset.generateThumbnail { image in
                        DispatchQueue.main.async {
                            completion(image, data, self.duration)
                        }
                    }
                } else {
                    completion(nil, nil, nil)
                }
            }
        }
    }
}
