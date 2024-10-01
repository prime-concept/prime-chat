import UIKit

final class ImageContentRenderer: ContentRenderer {
    static let messageContentType: MessageContent.Type = ImageContent.self

    static var messageModelType: MessageModel.Type {
        return MessageContainerModel<ImageContentView>.self
    }

    private var content: ImageContent
    private var contentMeta: ContentMeta
    private var actions: ContentRendererActions
    private var dependencies: ContentRendererDependencies

    private lazy var loadingIndicatorStub = UIActivityIndicatorView(style: .medium)

    private var onImageLoad: ((UIImage) -> Void)?
    private var minImage: UIImage?
    private var fullImage: UIImage?
    private var biggestImageYet: UIImage? {
        self.fullImage ?? self.minImage
    }

    var imageSizeFromMeta: CGSize? {
        return self.contentMeta.imageWidth
            .flatMap { width in self.contentMeta.imageHeight.flatMap { (width, $0) } }
            .flatMap { CGSize(width: $0.0, height: $0.1) }
    }

    var imageSizeFromContent: CGSize? {
        return self.content.content.size
    }

    private var onContentOpened: MessageContentOpeningCompletion?

    private init(
        content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) {
        self.content = content as! ImageContent // swiftlint:disable:this force_cast
        self.contentMeta = contentMeta
        self.actions = actions
        self.dependencies = dependencies

        self.loadInitialImage()
    }

    static func make(
        for content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) -> ContentRenderer {
        let guid = content.messageGUID
        
        if let guid = guid,
           let renderer = ContentRendererCache.shared.values[guid] as? Self,
           let content = content as? ImageContent {
            renderer.content = content
            renderer.contentMeta = contentMeta
            renderer.actions = actions
            return renderer
        }

        let renderer = Self.init(
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

    func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel {
        let contentControlValue: Int = {
            if meta.isFailed {
                return 100
            }

            if let progress = self.content.content.progress {
                return Int(progress * 100)
            }

            return Int.max
        }()

        var actions = self.actions
        actions.openContent = { [weak self] completion in
            self?.openImage(onContentOpened: completion)
        }

        return MessageContainerModel<ImageContentView>(
            uid: uid,
            meta: meta,
            contentControlValue: contentControlValue,
            shouldCalculateHeightOnMainThread: false,
            actions: actions,
            contentConfigurator: { view in
                weak var view = view

                let content = self.content.content
                let contentMeta = self.contentMeta

                view?.onTap = { [weak self] in
                    self?.openImage()
                }

                let onImageLoad: (UIImage) -> Void = { [weak view] image in
                    guard view?.guid == uid else { return }

                    self.loadingIndicatorStub.stopAnimating()
                    self.loadingIndicatorStub.isHidden = true

                    let viewModel = ImageContentView.Model(
                        blur: nil,
                        image: image,
                        progress: nil,
                        size: image.size
                    )
                    view?.update(with: viewModel)
                }

                if let loadedImage = self.biggestImageYet {
                    onImageLoad(loadedImage)
                    return
                }

                self.onImageLoad = onImageLoad

                let image: UIImage? = (contentMeta.imageBlurPreview)
                    .flatMap { Data(base64Encoded: $0) }
                    .flatMap { ImageMetaHelper.shared.blurPreview(from: $0) }

                let viewModel = ImageContentView.Model(
                    blur: image,
                    image: content.image,
                    progress: content.progress,
                    size: self.imageSizeFromMeta ?? self.imageSizeFromContent
                )

                if content.progress == nil {
                    self.placeLoadingIndicatorStub(on: view)
                }

                view?.update(with: viewModel)
            },
            heightCalculator: { viewWidth, _ in
                if let size = self.imageSizeFromMeta ?? self.imageSizeFromContent {
                    let height = size.height > 0 ? size.height : 1.0
                    let width = size.width > 0 ? size.width : 1.0

                    if height >= width {
                        return ImageContentView.fixedHeight
                    } else {
                        return viewWidth * (height / width) * ImageContentView.widthSpaceCoeff
                    }
                }
                return 0.75 * viewWidth
            }
        )
    }

    func preview() -> MessagePreview.ProcessedContent? {
        guard let path = self.content.content.path,
              let fileInfo = FileInfo(remotePath: path + "_min") else {
            return .photo(image: nil)
        }

        let loader = AsyncContentLoader<UIImage>(
            fileService: dependencies.fileService,
            fileInfo: fileInfo
        )
        return .photo(image: .init(loader: loader))
    }

    // MARK: - Private

    private func loadInitialImage() {
        self.loadMinImage { [weak self] image in
            if image == nil {
                self?.loadFullImage(completion: nil)
            }
        }
    }

    private func loadMinImage(completion: ((UIImage?) -> Void)? = nil) {
        self.loadImage(suffix: "_min") { [weak self] image in
            self?.minImage = image
            self?.callAndDisposeOnContentOpened(with: image)
            completion?(image)
        }
    }

    private func loadFullImage(completion: ((UIImage?) -> Void)? = nil) {
        self.loadImage { [weak self] image in
            self?.fullImage = image
            self?.callAndDisposeOnContentOpened(with: image)
            completion?(image)
        }
    }

    private func callAndDisposeOnContentOpened(with image: UIImage?) {
        guard let onContentOpened = self.onContentOpened else {
            return
        }
        self.openImage()
        onContentOpened()
        if image != nil {
            self.onContentOpened = nil
        }
    }

    private func placeLoadingIndicatorStub(on view: UIView?) {
        self.loadingIndicatorStub.removeFromSuperview()
        view?.addSubview(self.loadingIndicatorStub)
        self.loadingIndicatorStub.make(.edges, .equalToSuperview)
        self.loadingIndicatorStub.startAnimating()
    }

    private func loadImage(suffix: String = "", completion: ((UIImage?) -> Void)? = nil) {
        let cacheService = dependencies.cacheService
        let fileService = self.dependencies.fileService

        if suffix.isEmpty,
           let guid = self.content.messageGUID,
           let data = cacheService.retrieve(cacheKey: guid) {
            if let image = UIImage(data: data) {
                completion?(image)
                return
            }
        }

        guard let path = self.content.content.path,
              let fileInfo = FileInfo(remotePath: path + suffix) else {
            return
        }

        fileService.downloadAndDecode(
            file: fileInfo,
            skipCache: false,
            onMainQueue: false
        ) { [weak self] (image: UIImage?) in
            DispatchQueue.main.async {
                if let image {
                    self?.onImageLoad?(image)
                    completion?(image)
                    return
                }

                delay(1) {
                    self?.loadImage(suffix: suffix, completion: completion)
                }
            }
        }
    }

    private func openImage(onContentOpened: MessageContentOpeningCompletion? = nil) {
        guard let image = self.biggestImageYet else {
            self.onContentOpened = onContentOpened
            return
        }

        let controller = FullImageViewController()
        controller.set(image: image)
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve

        self.dependencies
            .chatDelegate?
            .requestPresentation(for: controller, completion: nil)

        onContentOpened?()
        self.onContentOpened = nil

        if image == self.fullImage {
            return
        }

        self.loadFullImage { [weak controller = controller] image in
            DispatchQueue.main.async {
                image.flatMap { controller?.set(image: $0) }
            }
        }
    }
}

// MARK: - UIImage+DataInitializable

extension UIImage: DataInitializable { }
