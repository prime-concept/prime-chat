import Foundation
import AVKit

protocol VideoMessageServiceProtocol {
    var storageBaseURL: URL? { get set }
    var authState: AuthState? { get set }

    func makeController(from file: FileInfo) -> AVPlayerViewController?
    func playVideo()
}

final class VideoMessageService: VideoMessageServiceProtocol {
    static let shared = VideoMessageService()

    private lazy var controller = AVPlayerViewController()

    var storageBaseURL: URL?
    var authState: AuthState?

    func makeController(from file: FileInfo) -> AVPlayerViewController? {
        let fullURL: URL
        let sharedPlayerItem: AVPlayerItem

        if let path = file.pathInCache {
            fullURL = URL(fileURLWithPath: path)
            let asset = AVURLAsset(url: fullURL)
            sharedPlayerItem = AVPlayerItem(asset: asset)
        } else {
            guard let baseURL = self.storageBaseURL, let bearerToken = self.authState?.bearerToken else {
                return nil
            }
            fullURL = baseURL.appendingPathComponent("files/\(file.privacy.rawValue)/\(file.uuid)")
            let headers: [String: String] = [
                "Authorization": bearerToken
            ]
            log(sender: self, "video message service: created item, url = \(fullURL.absoluteString)")
            let options = ["AVURLAssetHTTPHeaderFieldsKey": headers]

            let asset = AVURLAsset(url: fullURL, options: options)
            sharedPlayerItem = AVPlayerItem(asset: asset)
        }

        self.controller.player = AVPlayer(playerItem: sharedPlayerItem)
        self.controller.player?.replaceCurrentItem(with: sharedPlayerItem)

        return self.controller
    }

    func playVideo() {
        self.controller.player?.play()
    }
}
