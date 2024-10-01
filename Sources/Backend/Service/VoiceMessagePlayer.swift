import AVKit

extension Notification.Name {
    static let voiceMessagePlayerWillPlay = Self.init(rawValue: "VoiceMessagePlayerWillPlay")
}

final class VoiceMessagePlayer: NSObject {
    enum Status {
        case waiting
        case paused
        case playing
        case failed
    }

    private static let durationQueue = DispatchQueue(label: "VoiceMessagePlayer.duration")

    @ThreadSafe
    private var isObservingSharedPlayer = false
    private var timeObserver: Any?

    weak var sharedPlayer: AVPlayer?
    let file: FileInfo
    let item: AVPlayerItem

    var onPlaybackStatusChange: ((Status) -> Void)?
    var onCurrentPlayTimeChange: ((Int) -> Void)?

    var ownsSharedPlayer: Bool {
        self.sharedPlayer?.currentItem === self.item
    }

    var isPlaying: Bool {
        if !self.ownsSharedPlayer {
            return false
        }

        return self.sharedPlayer?.timeControlStatus == .playing
    }

    var isPaused: Bool {
        if !self.ownsSharedPlayer {
            return true
        }
        return self.sharedPlayer?.timeControlStatus == .paused
    }

    var time: Int {
        let time = self.item.currentTime()
        let currentTime = time.timescale == 0 ? 0.0 : round(Double(time.value) / Double(time.timescale))
        return Int(currentTime)
    }

    init(item: AVPlayerItem, sharedPlayer: AVPlayer, file: FileInfo) {
        self.item = item
        self.sharedPlayer = sharedPlayer
        self.file = file

        super.init()

        Notification.onReceive(.voiceMessagePlayerWillPlay) { [weak self] notification in
            self?.handleWillPlay(notification)
        }
    }

    deinit {
        log(sender: self, "[DEINIT] stopSharedPlayerObserving")
        self.stopSharedPlayerObserving()
    }

    func getDuration(completion: @escaping (Int) -> Void) {
        Self.durationQueue.async { [weak self] in
            guard let strongSelf = self else {
                return
            }

            let duration = strongSelf.item.asset.duration
            let durationValue = duration.timescale == 0
            ? 0.0
            : round(Double(duration.value) / Double(duration.timescale))
            
            DispatchQueue.main.async {
                completion(Int(durationValue))
            }
        }
    }

    func play() {
        log(sender: self, "WILL PLAY ITEM: \(item.desc)]")
        NotificationCenter.default.post(
            .voiceMessagePlayerWillPlay,
            userInfo: ["item": self.item]
        )

        self.sharedPlayer?.replaceCurrentItem(with: self.item)
        self.startSharedPlayerObserving()
        self.sharedPlayer?.playImmediately(atRate: 1.0)
    }

    func pause() {
        log(sender: self, "WILL PAUSE ITEM: \(item.desc)]")
        if self.ownsSharedPlayer {
            self.sharedPlayer?.pause()
        }
        self.stopSharedPlayerObserving()
    }

    func stop() {
        log(sender: self, "WILL STOP ITEM: \(item.desc)]")
        if self.ownsSharedPlayer {
            self.sharedPlayer?.pause()
            self.sharedPlayer?.seek(to: .zero)
        }
        self.stopSharedPlayerObserving()
    }

    private func handleWillPlay(_ notification: Notification) {
        let item = notification.userInfo?["item"] as? AVPlayerItem

        log(sender: self, "[WILL PLAY NOTIF] DID RECEIVE ITEM: \(item?.desc ?? "NULL")]")

        if item === self.item {
            log(sender: self, "[WILL PLAY NOTIF] ITS MY ITEM WILL DO NOTHING")
            return
        }

        if self.isPlaying {
            log(sender: self, "[WILL PLAY NOTIF] IS PLAYING, WILL PAUSE")
            self.pause()
            return
        }

        log(sender: self, "[WILL PLAY NOTIF] NOT PLAYING, WILL DO NOTHING")
    }
}

private extension VoiceMessagePlayer {
    func stopSharedPlayerObserving() {
        guard let sharedPlayer = self.sharedPlayer, self.isObservingSharedPlayer else {
            return
        }

        self.isObservingSharedPlayer = false

        sharedPlayer.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus), context: nil)
        self.item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: self.item)
        self.sharedPlayer?.removeTimeObserver(self.timeObserver)
    }

    func startSharedPlayerObserving() {
        guard let sharedPlayer = self.sharedPlayer, !self.isObservingSharedPlayer else {
            return
        }

        self.isObservingSharedPlayer = true

        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        self.timeObserver = sharedPlayer.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            let currentTime = time.timescale == 0 ? 0.0 : round(Double(time.value) / Double(time.timescale))
            self?.onCurrentPlayTimeChange?(Int(currentTime))
        }

        sharedPlayer.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayer.timeControlStatus), options: [.old, .new], context: nil
        )

        // Observe player item
        self.item.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.onSharedPlayerItemDidFinish(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: self.item
        )
    }

    @objc
    private func onSharedPlayerItemDidFinish(_ notification: Notification) {
        guard let sharedPlayerItem = notification.object as? AVPlayerItem,
              sharedPlayerItem === self.item else {
            return
        }

        self.stop()

        DispatchQueue.main.async {
            self.onPlaybackStatusChange?(.paused)
            self.onCurrentPlayTimeChange?(0)
        }
    }
}

extension VoiceMessagePlayer {
    // Bug in Swift compiler – https://bugs.swift.org/browse/SR-5872
    // swiftlint:disable:next block_based_kvo cyclomatic_complexity
    internal override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.ownsSharedPlayer else {
                return
            }

            guard object is AVPlayerItem || object is AVPlayer else {
                return
            }

            if keyPath == #keyPath(AVPlayerItem.status) {
                guard let value = change?[.newKey] as? Int,
                      let status = AVPlayerItem.Status(rawValue: value) else {
                    return
                }

                switch status {
                case .failed:
                    self.onPlaybackStatusChange?(.failed)
                default:
                    break
                }

                return
            }

            if keyPath == #keyPath(AVPlayer.timeControlStatus) {
                guard let value = change?[.newKey] as? Int,
                      let controlStatus = AVPlayer.TimeControlStatus(rawValue: value) else {
                    return
                }

                switch controlStatus {
                case .waitingToPlayAtSpecifiedRate:
                    self.onPlaybackStatusChange?(.waiting)
                case .paused:
                    self.onPlaybackStatusChange?(.paused)
                case .playing:
                    self.onPlaybackStatusChange?(.playing)
                @unknown default:
                    assertionFailure("Unsupported status")
                }

                return
            }
        }
    }
}

extension AVPlayerItem {
    var desc: String {
        "\(self.description.prefix(29)) \(self.asset.description.suffix(37))"
    }
}
