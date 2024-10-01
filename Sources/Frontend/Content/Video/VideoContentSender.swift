import UIKit

final class VideoContentSender: ContentSender {
    lazy var content: MessageContent? = self.makeInitialContent()

    private static let metaGenerationQueue = DispatchQueue(label: "VideoContentSender.meta")

    private let name: String
    private let previewImage: UIImage
    private let messageContent: Data
    private let duration: Double

    private(set) var messageGUID: String = UUID().uuidString

    var attachmentPreview: AttachmentPreview? {
        AttachmentPreview(
            id: self.messageGUID,
            previewImage: self.previewImage,
            mediaAssetType: .video,
            duration: self.duration
        )
    }

    init(previewImage: UIImage, name: String, messageContent: Data, duration: Double) {
        self.previewImage = previewImage
        self.name = name
        self.messageContent = messageContent
        self.duration = duration
    }

    private var updates: ((MessageContent, ContentMeta) -> Void)?

    // swiftlint:disable:next function_body_length
    func send(
        channelID: String,
        using dependencies: ContentSenderDependencies,
        updates: @escaping (MessageContent, ContentMeta) -> Void,
        completion: @escaping (Result<MessageContent, Error>) -> Void
    ) {
        log(sender: self, "[VIDEO] WILL SEND VIDEO TO CHAT: \(channelID)")

        self.updates = updates
        Self.metaGenerationQueue.async { [weak self] in
            log(sender: self, "[VIDEO] WILL GENERATE META")

            guard
                let self = self,
                let videoContent = self.content as? VideoContent,
                let size = videoContent.content.size,
                let image = videoContent.content.image
            else {
                log(sender: self, "[VIDEO] FAILED TO GENERATE META. SEND ABORTED")
                return
            }

            let name = self.name
            let guid = self.messageGUID
            let duration = self.duration
            let data = self.messageContent

            let blurPreviewData = ImageMetaHelper.shared.blurPreviewData(from: image)

            log(
                sender: self,
                """
                [VIDEO] META GENERATED OK: NAME: \(name), \
                GUID: \(guid), DUR: \(duration), LEN: \(data.count), \
                PREVIEW LEN: \(blurPreviewData?.count ?? -1)
                """
            )

            let contentMeta = ContentMeta(
                videoDuration: duration,
                videoWidth: Int(size.width),
                videoHeight: Int(size.height),
                videoBlurPreview: blurPreviewData?.base64EncodedString(),
                documentName: name
            )

            self.notifyProgress(0.1, contentMeta: contentMeta)

            self.cacheData(data, with: dependencies)

            log(sender: self, "[VIDEO] UPLOAD STARTED!")

            dependencies.fileService.uploadImmediate(
                filename: name,
                data: data,
                mimeType: . video,
                progress: { [weak self] progress in
                    self?.notifyProgress(progress, contentMeta: contentMeta)
                    log(sender: self, "[VIDEO] UPLOAD PROGRESS: \(progress)")
                },
                completion: { [weak self] result in
                    switch result {
                    case .success(let files):
                        log(sender: self, "[VIDEO] UPLOAD SUCCESS. FILES COUNT: \(files.count)")

                        guard let file = files.first else {
                            log(sender: self, "[VIDEO] NO FILES UPLOADED! TERMINATE, DONT SEND MESSAGE")
                            return
                        }

                        let newContent = VideoContent.Content(
                            path: file.path,
                            progress: nil,
                            size: size,
                            image: image
                        )

                        log(sender: self, "[VIDEO] DID UPLOAD FILE! \(file.name) + \(file.path)")

                        DispatchQueue.main.async {
                            self?.sendMessage(
                                guid: guid,
                                channelID: channelID,
                                content: VideoContent(
                                    messageGUID: guid,
                                    content: newContent
                                ),
                                contentMeta: contentMeta,
                                dependencies: dependencies,
                                completion: { result in
                                    log(sender: self, "[VIDEO] DID UPLOAD+SEND MESSAGE! \(result)")
                                    completion(result)
                                }
                            )
                        }
                    case .failure(let error):
                        log(sender: self, "[VIDEO] UPLOAD FAILURE, ERROR: \(error)")
                        self?.notifyProgress(1, contentMeta: contentMeta)
                        DispatchQueue.main.async { completion(.failure(error)) }
                    }
                }
            )
        }
    }

    private func notifyProgress(_ progress: Float?, contentMeta: ContentMeta) {
        guard let videoContent = self.content as? VideoContent else {
            return
        }
        let progress = progress == nil ? progress : max(0.1, progress ?? 0)
        let updated = videoContent.content.copyUpdating(progress: progress)
        let content = VideoContent(messageGUID: self.messageGUID, content: updated)
        self.content = content
        self.updates?(content, contentMeta)
    }

    // swiftlint:disable:next function_parameter_count
    private func sendMessage(
        guid: String,
        channelID: String,
        content: MessageContent,
        contentMeta: ContentMeta,
        dependencies: ContentSenderDependencies,
        completion: @escaping (Result<MessageContent, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            dependencies.sendMessageService.send(
                guid: guid,
                channelID: channelID,
                content: content,
                contentMeta: contentMeta,
                replyTo: nil
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        completion(.success(content))
                    }
                    self?.updates = nil
                }
            }
        }
    }

    private func makeInitialContent() -> MessageContent {
        let image = self.previewImage
        let size = ImageMetaHelper.shared.size(from: image)

        let content = VideoContent.Content(
            path: nil,
            progress: nil,
            size: size,
            image: image
        )

        return VideoContent(messageGUID: self.messageGUID, content: content)
    }
}

extension VideoContentSender {
    static var draftAttachmentType: String { "VIDEO" }

    struct DraftProperties: Codable {
        let messageGUID: String
        let duration: Double
        let name: String
    }

    var contentPreview: MessagePreview.Content {
        .init(
            processed: .video(preview: AsyncContentProvider<UIImage>(value: self.previewImage)),
            raw: .init(type: VideoContent.messageType, content: self.messageGUID, meta: [:])
        )
    }

    static func from(
        draftAttachment: DraftAttachment,
        dependencies: ContentSenderDependencies
    ) -> ContentSender? {
        guard draftAttachment.type == Self.draftAttachmentType else {
            return nil
        }

        let decoder = ChatJSONDecoder()

        guard let props = try? decoder.decode(
            DraftProperties.self,
            from: draftAttachment.properties.data(using: .utf8) ?? .init()
        ) else {
            return nil
        }

        let cacheService = dependencies.cacheService

        let previewFile = self.fileInfo(
            from: cacheService,
            properties: props,
            extension: "jpg"
        )

        let videoFile = self.fileInfo(
            from: cacheService,
            properties: props
        )

        guard let previewData = cacheService.retrieve(file: previewFile),
              let videoData = cacheService.retrieve(file: videoFile) else {
            return nil
        }

        guard let preview = UIImage(data: previewData) else {
            return nil
        }

        let sender = VideoContentSender(
            previewImage: preview,
            name: props.name,
            messageContent: videoData,
            duration: props.duration
        )
        sender.messageGUID = props.messageGUID

        return sender
    }

    func makeDraftAttachment(with dependencies: ContentSenderDependencies) -> DraftAttachment? {
        let encoder = JSONEncoder()

        let previewData = self.previewImage.jpegData(compressionQuality: 0.8)

        self.cacheData(previewData, with: dependencies, extension: "jpg")
        self.cacheData(self.messageContent, with: dependencies)

        let properties = DraftProperties(
            messageGUID: self.messageGUID,
            duration: self.duration,
            name: self.name
        )

        guard let props = try? encoder.encode(properties),
              let propsString = String(data: props, encoding: .utf8) else {
            return nil
        }

        return DraftAttachment(type: Self.draftAttachmentType, properties: propsString)
    }

    private static func fileInfo(
        from cacheService: DraftsCacheServiceProtocol,
        properties props: DraftProperties,
        extension: String? = nil
    ) -> FileInfo {
        var file = FileInfo(
            uuid: props.messageGUID,
            fileName: props.name,
            defaultExtension: `extension`
        )

        if let ext = `extension` {
            file.fileName = (file.fileName ?? "") + ".\(ext)"
        }

        if let url = cacheService.exists(file: file) {
            file.pathInCache = url.path
        }

        return file
    }

    @discardableResult
    private func cacheData(
        _ data: Data?,
        with dependencies: ContentSenderDependencies,
        `extension`: String? = nil
    ) -> URL? {
        guard let data = data else {
            return nil
        }

        var file = FileInfo(uuid: self.messageGUID, defaultExtension: `extension`)
        var name = self.name
        if let ext = `extension` {
            name += ".\(ext)"
        }

        file.fileName = name
        return dependencies.cacheService.save(file: file, data: data)
    }
}
