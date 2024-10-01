import UIKit

private var documentContentPendingDownloads = [String: (() -> Void?)]()

final class DocumentContentRenderer: ContentRenderer {
    static let messageContentType: MessageContent.Type = DocumentContent.self

    static var messageModelType: MessageModel.Type {
        return MessageContainerModel<DocumentContentView>.self
    }

    private var content: DocumentContent
    private var contentMeta: ContentMeta
    private var actions: ContentRendererActions
    private var dependencies: ContentRendererDependencies

    private var onDocumentLoad: ((URL) -> Void)?
    private var onDocumentFailureLoad: (() -> Void)?
    private var onStartDownloadDocument: (() -> Void)?
    private var onChangeDownloadProgress: ((Float) -> Void)?
    private var isDownloadInProgress = false

    private var onContentOpened: MessageContentOpeningCompletion?

    private init(
        content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) {
        self.content = content as! DocumentContent // swiftlint:disable:this force_cast
        self.contentMeta = contentMeta
        self.actions = actions
        self.dependencies = dependencies
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
           let content = content as? DocumentContent {
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

    // swiftlint:disable:next function_body_length
    func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel {
        let contentControlValue: Int = {
            if meta.isFailed {
                return 100
            }
            
            switch self.content.content.progress {
            case .none:
                return Int.max
            case .some(let progress):
                return Int(progress * 100)
            }
        }()

        var actions = self.actions
        actions.openContent = { completion in
            self.onContentOpened = completion
            self.showDocument()
        }

        let contentConfigurator: (DocumentContentView) -> Void = { view in
            let content = self.content.content
            let contentMeta = self.contentMeta
            let isIncome = meta.author == .anotherUser

            let documentName = contentMeta.documentName ?? content.name
            let documentSize = contentMeta.documentSize ?? content.size

            let onDocumentLoaded: (URL) -> Void = { [weak view] url in
                guard view?.guid == uid else { return }

                let viewModel = DocumentContentView.Model(
                    name: documentName,
                    url: url,
                    progress: nil,
                    size: documentSize,
                    isIncome: isIncome
                )
                view?.update(with: viewModel)
            }

            let onDocumentFailureLoad: () -> Void = { [weak view] in
                let viewModel = DocumentContentView.Model(
                    name: documentName,
                    url: nil,
                    progress: nil,
                    size: documentSize,
                    isIncome: isIncome
                )
                view?.update(with: viewModel)
            }

            self.onStartDownloadDocument = { [weak view] in
                let viewModel = DocumentContentView.Model(
                    name: documentName,
                    url: nil,
                    progress: 0,
                    size: documentSize,
                    isIncome: isIncome
                )
                view?.update(with: viewModel)
            }

            let onChangeDownloadProgress: (Float) -> Void = { [weak view] progress in
                let viewModel = DocumentContentView.Model(
                    name: documentName,
                    url: nil,
                    progress: progress,
                    size: documentSize,
                    isIncome: isIncome
                )
                view?.update(with: viewModel)
            }

            if let loadedDocumentURL = self.documentURL {
                onDocumentLoaded(loadedDocumentURL)
            } else {
                self.onDocumentLoad = onDocumentLoaded
                self.onDocumentFailureLoad = onDocumentFailureLoad
                self.onChangeDownloadProgress = onChangeDownloadProgress

                let viewModel = DocumentContentView.Model(
                    name: documentName,
                    url: nil,
                    progress: content.progress,
                    size: documentSize,
                    isIncome: isIncome
                )
                view.update(with: viewModel)
            }

            view.onDocumentButtonClick = { [weak self] in
                guard let self = self, !self.isDownloadInProgress else {
                    return
                }

                self.showDocument()
            }
        }

        return MessageContainerModel<DocumentContentView>(
            uid: uid,
            meta: meta,
            contentControlValue: contentControlValue,
            shouldCalculateHeightOnMainThread: false,
            actions: actions,
            contentConfigurator: contentConfigurator,
            heightCalculator: { _, _ in
                DocumentContentView.height
            }
        )
    }

    func preview() -> MessagePreview.ProcessedContent? {
        .document(name: self.contentMeta.documentName, size: self.contentMeta.documentSize)
    }

    func showDocument() {
        if self.documentURL != nil {
            self.openDocument()
            return
        }

        if self.content.content.path != nil {
            self.loadDocument()
        }
    }

    // MARK: - Private

    private func loadDocument() {
        guard let fileInfo = self.fileInfo else {
            return
        }

        self.onStartDownloadDocument?()

        self.isDownloadInProgress = true
        dependencies.fileService.download(
            file: fileInfo,
            skipCache: false,
            progress: { [weak self] progress in
                self?.onChangeDownloadProgress?(progress)
            },
            completion: { [weak self] (documentURL: URL?) in
                DispatchQueue.main.async {
                    self?.isDownloadInProgress = false
                    guard let documentURL = self?.documentURL else {
                        self?.onDocumentFailureLoad?()
                        delay(1) {
                            self?.loadDocument()
                        }
                        return
                    }
                    
                    self?.onDocumentLoad?(documentURL)
                    self?.openDocument()
                }
            }
        )
    }

    private func openDocument() {
        defer {
            self.onContentOpened?()
            self.onContentOpened = nil
        }
        
        guard let documentURL = self.documentURL else {
            return
        }

        let controller = DocumentPreviewController(documentURLs: [documentURL])
        let navigation = StylizedNavigationContoller(
            rootViewController: controller
        )

        self.dependencies.chatDelegate?.requestPresentation(
            for: navigation,
            completion: nil
        )
    }

    private var fileInfo: FileInfo? {
        var fileInfos = [FileInfo]()
        var remoteFileInfo: FileInfo?

        if let guid = self.content.messageGUID {
            var fileInfo = FileInfo(uuid: guid)
            fileInfo.fileName = self.contentMeta.documentName
            fileInfos.append(fileInfo)
        }

        if let path = self.content.content.path,
           var fileInfo = FileInfo(remotePath: path) {
            fileInfo.fileName = self.contentMeta.documentName
            remoteFileInfo = fileInfo
            fileInfos.append(fileInfo)
        }

        var cachedFileInfo: FileInfo?

        for fileInfo in fileInfos {
            if let cachedURL = dependencies.cacheService.exists(file: fileInfo) {
                cachedFileInfo = fileInfo
                cachedFileInfo?.pathInCache = cachedURL.path
                break
            }
        }

        let fileInfo = cachedFileInfo ?? remoteFileInfo
        return fileInfo
    }

    private var documentURL: URL? {
        guard let fileInfo = self.fileInfo,
              let path = fileInfo.pathInCache else {
            return nil
        }

        return URL(fileURLWithPath: path)
    }
}
