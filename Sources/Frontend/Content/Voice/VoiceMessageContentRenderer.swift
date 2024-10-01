import UIKit
import CoreMedia

final class VoiceMessageContentRenderer: ContentRenderer {
    static let messageContentType: MessageContent.Type = VoiceMessageContent.self

    static var messageModelType: MessageModel.Type {
        MessageContainerModel<VoiceMessageContentView>.self
    }

    private var content: VoiceMessageContent
    private var contentMeta: ContentMeta
    private var actions: ContentRendererActions
    private var dependencies: ContentRendererDependencies

    private var voiceMessagePlayer: VoiceMessagePlayer?
    private var isVoiceMessagePlayerError = false
    private var messageDuration: Int?

    private var onContentOpened: MessageContentOpeningCompletion?

    private var onVoiceMessagePlayerReady: ((VoiceMessagePlayer) -> Void)?
    private var onVoiceMessagePlayerError: (() -> Void)?

    private init(
        content: VoiceMessageContent,
        meta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) {
        self.content = content
        self.contentMeta = meta
        self.actions = actions
        self.dependencies = dependencies
    }

    deinit {
        self.voiceMessagePlayer = nil
    }

    static func make(
        for content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) -> ContentRenderer {
        guard let content = content as? VoiceMessageContent else {
            fatalError("Incorrect content type")
        }

        // Swift.print("WILL MAKE FOR GUID: \(content.messageGUID ?? "") \(Self.self)")

        let guid = content.messageGUID

        if let guid = guid, let renderer = ContentRendererCache.shared.values[guid] as? Self {
            renderer.content = content
            renderer.contentMeta = contentMeta
            renderer.actions = actions
            return renderer
        }

        let renderer = Self.init(
            content: content,
            meta: contentMeta,
            actions: actions,
            dependencies: dependencies
        )

        if let guid = guid {
            ContentRendererCache.shared.values[guid] = renderer
        }

        return renderer
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel {
        self.redirectContentToCache()

        let controlValue: Int = {
            if case .local = self.content.content {
                return Int.min
            }
            return Int.max
        }()

        var actions = self.actions
        actions.openContent = { completion in
            guard let player = self.voiceMessagePlayer else {
                self.onContentOpened = completion
                return
            }

            if !player.isPlaying {
                player.play()
            }

            completion()
        }

        let contentConfigurator: (VoiceMessageContentView) -> Void = { playerView in
            // First update, skip duration fetching
            playerView.update(
                with: VoiceMessageContentView.Model(status: .paused, time: 0, duration: nil),
                meta: meta
            )

            typealias Status = VoiceMessageContentView.Model.Status
            
            self.onVoiceMessagePlayerReady = { [weak self, weak playerView] voiceMessagePlayer in
                let updateViewWithCurrentTime: (Status) -> Void = { [weak voiceMessagePlayer] status in
                    guard let voiceMessagePlayer = voiceMessagePlayer else {
                        return
                    }
                    
                    self?.makeViewModel(
                        player: voiceMessagePlayer,
                        status: status) { viewModel in
                            playerView?.update(with: viewModel, meta: meta)
                        }
                }

                // Second update with actual duration
                updateViewWithCurrentTime(voiceMessagePlayer.isPlaying ? .playing : .paused)

                voiceMessagePlayer.onCurrentPlayTimeChange = { [weak voiceMessagePlayer] _ in
                    guard let voiceMessagePlayer = voiceMessagePlayer else {
                        return
                    }

                    updateViewWithCurrentTime(voiceMessagePlayer.isPlaying ? .playing : .paused)
                }

                voiceMessagePlayer.onPlaybackStatusChange = { status in
                    let viewStatus: VoiceMessageContentView.Model.Status = {
                        switch status {
                        case .failed:
                            return .error
                        case .paused:
                            return .paused
                        case .playing:
                            return .playing
                        case .waiting:
                            return .waiting
                        }
                    }()

                    updateViewWithCurrentTime(viewStatus)
                }

                playerView?.onPlayButtonClick = {
                    voiceMessagePlayer.isPlaying ? voiceMessagePlayer.pause() : voiceMessagePlayer.play()
                }

                playerView?.onScrub = { [weak voiceMessagePlayer] ratio in
                    let duration = Double(self?.messageDuration ?? 0) * ratio
                    voiceMessagePlayer?.sharedPlayer?.seek(to: CMTime.init(seconds: duration, preferredTimescale: 1))
                }

                if let completion = self?.onContentOpened {
                    if !voiceMessagePlayer.isPlaying {
                        voiceMessagePlayer.play()
                    }
                    completion()
                    self?.onContentOpened = nil
                }
            }

            self.onVoiceMessagePlayerError = { [weak playerView] in
                playerView?.update(
                    with: VoiceMessageContentView.Model(status: .error, time: 0, duration: nil),
                    meta: meta
                )
            }

            if let voiceMessagePlayer = self.voiceMessagePlayer {
                self.onVoiceMessagePlayerReady?(voiceMessagePlayer)
            }

            if self.isVoiceMessagePlayerError {
                self.onVoiceMessagePlayerError?()
            }
        }

        return MessageContainerModel<VoiceMessageContentView>(
            uid: uid,
            meta: meta,
            contentControlValue: controlValue,
            shouldCalculateHeightOnMainThread: false,
            actions: actions,
            contentConfigurator: contentConfigurator,
            heightCalculator: { _, _ in
                VoiceMessageContentView.height
            }
        )
    }

    func preview() -> MessagePreview.ProcessedContent? {
        .voice
    }

    // MARK: - Private

    private func makeViewModel(
        player: VoiceMessagePlayer,
        status: VoiceMessageContentView.Model.Status,
        completion: @escaping (VoiceMessageContentView.Model) -> Void
    ) {
        let time = player.time

        if let duration = self.messageDuration {
            completion(VoiceMessageContentView.Model(status: status, time: time, duration: duration))
        } else {
            player.getDuration { [weak self] duration in
                self?.messageDuration = duration
                completion(VoiceMessageContentView.Model(status: status, time: time, duration: duration))
            }
        }
    }

    private func makeVoiceMessagePlayer() {
        let voiceMessageService = dependencies.voiceMessageService

        guard let fileInfo = self.fileInfo else {
            self.voiceMessagePlayer = nil
            self.isVoiceMessagePlayerError = true
            self.onVoiceMessagePlayerError?()

            return
        }

        voiceMessageService.makeVoiceMessagePlayer(file: fileInfo) { [weak self] voiceMessagePlayer in
            log(
                sender: self,
                "[VMP] WILL SET \(String(describing: voiceMessagePlayer)) VMP TO SELF: \(String(describing: self))"
            )
            self?.voiceMessagePlayer = voiceMessagePlayer
            self?.isVoiceMessagePlayerError = false

            voiceMessagePlayer.flatMap { self?.onVoiceMessagePlayerReady?($0) }
        }
    }
}

fileprivate extension VoiceMessageContentRenderer {
    func redirectContentToCache() {
        let fileService = self.dependencies.fileService
        let cacheService = self.dependencies.cacheService

        guard let fileInfo = self.fileInfo  else {
            return
        }

        if fileInfo.pathInCache != nil {
            self.makeVoiceMessagePlayer()
            return
        }

        self.loadVoiceMessage(for: fileInfo)
    }

    private func loadVoiceMessage(for fileInfo: FileInfo) {
        let fileService = self.dependencies.fileService
        let cacheService = self.dependencies.cacheService

        fileService.download(file: fileInfo, skipCache: true) { [weak self] data in
            if let data {
                _ = cacheService.save(file: fileInfo, data: data)
                self?.makeVoiceMessagePlayer()
                return
            }

            delay(1) {
                self?.loadVoiceMessage(for: fileInfo)
            }
        }
    }

    private static func fileInfo(
        with content: VoiceMessageContent,
        contentMeta: ContentMeta,
        dependencies: ContentRendererDependencies
    ) -> FileInfo? {
        var fileInfos = [FileInfo]()
        var remoteFileInfo: FileInfo?

        if case var .remote(file: fileInfo) = content.content {
            fileInfo.defaultExtension = "m4a"
            fileInfo.fileName = contentMeta.documentName
            remoteFileInfo = fileInfo
            fileInfos.append(fileInfo)
        }

        if let guid = content.messageGUID {
            var fileInfo = FileInfo(uuid: guid, defaultExtension: "m4a")
            fileInfo.fileName = contentMeta.documentName
            fileInfos.append(fileInfo)
        }

        var cachedFileInfo: FileInfo?
        
        let cacheService = dependencies.cacheService

        for fileInfo in fileInfos {
            if let cachedURL = cacheService.exists(file: fileInfo) {
                cachedFileInfo = fileInfo
                cachedFileInfo?.pathInCache = cachedURL.path
                break
            }
        }

        let fileInfo = cachedFileInfo ?? remoteFileInfo
        return fileInfo
    }

    private var fileInfo: FileInfo? {
        Self.fileInfo(with: self.content, contentMeta: self.contentMeta, dependencies: self.dependencies)
    }
}
