import UIKit

final class VideoContentRenderer: ContentRenderer {
    static let messageContentType: MessageContent.Type = VideoContent.self

    static var messageModelType: MessageModel.Type {
        return MessageContainerModel<VideoContentView>.self
    }

    private var content: VideoContent
    private var contentMeta: ContentMeta
    private var actions: ContentRendererActions
    private var dependencies: ContentRendererDependencies
    private let videoMessageService: VideoMessageServiceProtocol

    private var onImageLoad: ((UIImage) -> Void)?
    private var image: UIImage?
    private var duration: Double?

    private var onContentOpened: MessageContentOpeningCompletion?

    var imageSizeFromMeta: CGSize? {
        return self.contentMeta.videoWidth
            .flatMap { width in self.contentMeta.videoHeight.flatMap { (width, $0) } }
            .flatMap { CGSize(width: $0.0, height: $0.1) }
    }

    var imageSizeFromContent: CGSize? {
        return self.content.content.size
    }

    private init(
        content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies,
        videoMessageService: VideoMessageServiceProtocol = VideoMessageService.shared
    ) {
        self.content = content as! VideoContent // swiftlint:disable:this force_cast
        self.contentMeta = contentMeta
        self.actions = actions
        self.dependencies = dependencies
        self.videoMessageService = videoMessageService

        self.loadImage()
    }

    static func make(
        for content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) -> ContentRenderer {
        let guid = content.messageGUID

        // Swift.print("WILL MAKE FOR GUID: \(guid ?? "") \(Self.self)")

        if let guid = guid,
           let renderer = ContentRendererCache.shared.values[guid] as? Self,
           let content = content as? VideoContent {
            renderer.content = content
            renderer.contentMeta = contentMeta
            renderer.actions = actions
            return renderer
        }

        let renderer = VideoContentRenderer(
            content: content,
            contentMeta: contentMeta,
            actions: actions,
            dependencies: dependencies
        )

        if let guid = guid {
            ContentRendererCache.shared.values[guid] = renderer
        }

        return renderer
    }
    // swiftlint:disable:next function_body_length
    func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel {
        self.redirectContentToCache()

        let contentControlValue: Int = {
            switch self.content.content.progress {
            case .none:
                return Int.max
            case .some(let progress):
                return Int(progress * 100)
            }
        }()

        var actions = self.actions
        actions.openContent = { completion in
            self.openVideoPlayer(onContentOpened: completion)
        }

        return MessageContainerModel<VideoContentView>(
            uid: uid,
            meta: meta,
            contentControlValue: contentControlValue,
            shouldCalculateHeightOnMainThread: false,
            actions: actions,
            contentConfigurator: { [weak self] view in
                weak var view = view

                guard let self, view?.guid == uid else { return }

                let content = self.content.content
                let contentMeta = self.contentMeta

                let onImageLoad: (UIImage) -> Void = { [weak view] image in
                    guard view?.guid == uid else { return }

                    let viewModel = VideoContentView.Model(
                        blur: nil,
                        image: image,
                        progress: nil,
                        size: image.size,
                        duration: contentMeta.videoDuration
                    )

                    view?.update(with: viewModel)
                }

                view?.onTap = { [weak self] in
                    self?.openVideoPlayer()
                }

                if let loadedImage = self.image {
                    onImageLoad(loadedImage)
                    return
                }

                self.onImageLoad = onImageLoad

                let previewBase64 = contentMeta.imageBlurPreview ?? contentMeta.videoBlurPreview

                let blur: UIImage? = previewBase64
                    .flatMap { Data(base64Encoded: $0) }
                    .flatMap { ImageMetaHelper.shared.blurPreview(from: $0) }

                var image = content.image
                
                let cacheService = dependencies.cacheService
                let fileService = dependencies.fileService

                if let fileInfo = self.fileInfo, image == nil {
                    var cachedImage: UIImage? = fileService.cached(file: fileInfo)
                    if cachedImage == nil {
                        let cacheKey = fileInfo.cacheKey.appending(".jpg")
                        let data = cacheService.retrieve(cacheKey: cacheKey)
                        if let data = data {
                            cachedImage = UIImage(data: data)
                        }
                    }
                    image = cachedImage
                }

                let viewModel = VideoContentView.Model(
                    blur: blur,
                    image: image,
                    progress: content.progress,
                    size: self.imageSizeFromMeta ?? self.imageSizeFromContent,
                    duration: contentMeta.videoDuration
                )

                view?.update(with: viewModel)

                self.loadImage()
            },
            heightCalculator: { viewWidth, _ in
                if let size = self.imageSizeFromMeta ?? self.imageSizeFromContent {
                    let height = size.height > 0 ? size.height : 1.0
                    let width = size.width > 0 ? size.width : 1.0

                    if height >= width {
                        return VideoContentView.fixedHeight
                    } else {
                        return viewWidth * (height / width) * VideoContentView.widthSpaceCoeff
                    }
                }
                return 0.75 * viewWidth
            }
        )
    }

    func preview() -> MessagePreview.ProcessedContent? {
        let fileService = dependencies.fileService

        guard let path = self.content.content.path,
              let fileInfo = FileInfo(remotePath: path + "_min") else {
            return .video(preview: nil)
        }

        let loader = AsyncContentLoader<UIImage>(fileService: fileService, fileInfo: fileInfo)
        return .video(preview: .init(loader: loader))
    }

    // MARK: - Private

    private func loadImage() {
        let fileService = dependencies.fileService

        guard let path = self.content.content.path,
              let fileInfo = FileInfo(remotePath: path + "_min") else {
            return
        }

        fileService.downloadAndDecode(
            file: fileInfo,
            skipCache: false,
            onMainQueue: false
        ) { [weak self] (image: UIImage?) in
            guard let image else {
                delay(1) { self?.loadImage() }
                return
            }

            self?.image = image

            DispatchQueue.main.async {
                self?.onImageLoad?(image)
            }
        }
    }

    private func openVideoPlayer(onContentOpened: MessageContentOpeningCompletion? = nil) {
        guard let fileInfo = self.fileInfo else {
            self.onContentOpened = onContentOpened
            self.waitUntilVideoIsAvailable()
            return
        }

        if fileInfo.pathInCache == nil, onContentOpened != nil {
            self.onContentOpened = onContentOpened
            self.waitUntilVideoIsAvailable()
            return
        }

        guard let controller = self.videoMessageService.makeController(from: fileInfo) else {
            self.onContentOpened = onContentOpened
            self.waitUntilVideoIsAvailable()
            return
        }

        self.dependencies.chatDelegate?.requestPresentation(for: controller) { [weak self] in
            self?.videoMessageService.playVideo()
            onContentOpened?()
            self?.onContentOpened = nil
        }
    }

    private func waitUntilVideoIsAvailable() {
        delay(0.5) {
            self.openVideoPlayer(onContentOpened: self.onContentOpened)
        }
    }
}

fileprivate extension VideoContentRenderer {
    @ThreadSafe
    private static var videoContentPendingDownloads = [String: VideoContentRenderer]()

    func redirectContentToCache() {
        let cacheService = self.dependencies.cacheService
        let fileService = dependencies.fileService

        guard let fileInfo = self.fileInfo  else {
            return
        }

        if fileInfo.pathInCache != nil {
            return
        }

        if Self.videoContentPendingDownloads[fileInfo.cacheKey] != nil {
            return
        }

        Self.videoContentPendingDownloads[fileInfo.cacheKey] = self

        fileService
            .download(file: fileInfo, skipCache: true) { [weak self] data in
                defer {
                    Self.videoContentPendingDownloads[fileInfo.cacheKey] = nil
                }
                guard let data = data else {
                    delay(1) {
                        self?.redirectContentToCache()
                    }
                    return
                }
                _ = cacheService.save(file: fileInfo, data: data)
            }
    }

    private static func fileInfo(
        with content: VideoContent,
        contentMeta: ContentMeta,
        dependencies: ContentRendererDependencies,
        ext: String = "mp4"
    ) -> FileInfo? {
        var fileInfos = [FileInfo]()
        var remoteFileInfo: FileInfo?

        if let guid = content.messageGUID {
            var fileInfo = FileInfo(uuid: guid, defaultExtension: ext)
            fileInfo.fileName = contentMeta.documentName
            fileInfos.append(fileInfo)
        }

        if let path = content.content.path,
           var fileInfo = FileInfo(remotePath: path, defaultExtension: ext) {
            fileInfo.fileName = contentMeta.documentName
            remoteFileInfo = fileInfo
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
        Self.fileInfo(
            with: self.content,
            contentMeta: self.contentMeta,
            dependencies: self.dependencies
        )
    }
}
