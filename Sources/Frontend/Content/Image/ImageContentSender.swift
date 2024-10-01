import UIKit

final class ImageContentSender: ContentSender {
    private static let metaGenerationQueue = DispatchQueue(label: "ImageContentSender.meta")

    private let image: UIImage
    private let name: String
    private let messageContent: Data

    private(set) var messageGUID: String = UUID().uuidString

    var attachmentPreview: AttachmentPreview? {
        AttachmentPreview(id: self.messageGUID, previewImage: self.image, mediaAssetType: .photo, duration: nil)
    }

    private var updates: ((MessageContent, ContentMeta) -> Void)?

    init(image: UIImage, name: String, messageContent: Data) {
        self.image = image
        self.name = name
        self.messageContent = messageContent
    }

    lazy var content: MessageContent? = self.makeInitialContent()

    private func makeInitialContent() -> MessageContent {
        let size = ImageMetaHelper.shared.size(from: self.image)

        let content = ImageContent.Content(
            path: "",
            progress: nil,
            size: size,
            image: image
        )

        return ImageContent(messageGUID: self.messageGUID, content: content)
    }

    func send(
        channelID: String,
        using dependencies: ContentSenderDependencies,
        updates: @escaping (MessageContent, ContentMeta) -> Void,
        completion: @escaping (Result<MessageContent, Error>) -> Void
    ) {
        self.updates = updates
        Self.metaGenerationQueue.async { [weak self] in
            guard let image = self?.image,
                  let name = self?.name,
                  let messageID = self?.messageGUID,
                  let messageContent = self?.messageContent,
                  let blurPreviewData = ImageMetaHelper.shared.blurPreviewData(from: image),
                  let imageContent = self?.content as? ImageContent,
                  let size = imageContent.content.size else {
                return
            }

            let contentMeta = ContentMeta(
                imageWidth: Int(size.width),
                imageHeight: Int(size.height),
                imageBlurPreview: blurPreviewData.base64EncodedString(),
                documentName: name
            )

            self?.notifyProgress(0.1, contentMeta: contentMeta)

            dependencies.cacheService.save(cacheKey: messageID, data: messageContent)
            dependencies.fileService.uploadImmediate(
                filename: name,
                data: messageContent,
                mimeType: .imagePNG,
                progress: { progress in
                    self?.notifyProgress(progress, contentMeta: contentMeta)
                },
                completion: { result in
                    switch result {
                    case .success(let files):
                        if let file = files.first {
                            let newContent = ImageContent.Content(
                                path: file.path,
                                progress: nil,
                                size: imageContent.content.size,
                                image: image
                            )

                            DispatchQueue.main.async {
                                self?.sendMessage(
                                    guid: messageID,
                                    channelID: channelID,
                                    content: ImageContent(
                                        messageGUID: messageID,
                                        content: newContent
                                    ),
                                    contentMeta: contentMeta,
                                    dependencies: dependencies,
                                    completion: completion
                                )
                            }
                        }
                    case .failure(let error):
                        self?.notifyProgress(1, contentMeta: contentMeta)
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            )
        }
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

    private func notifyProgress(_ progress: Float?, contentMeta: ContentMeta) {
        guard let imageContent = self.content as? ImageContent else {
            return
        }
        let progress = progress == nil ? progress : max(0.1, progress ?? 0)
        let updated = imageContent.content.copyUpdating(progress: progress)
        let content = ImageContent(messageGUID: self.messageGUID, content: updated)
        self.content = content
        self.updates?(content, contentMeta)
    }
}

extension ImageContentSender {
    static var draftAttachmentType: String { "IMAGE" }

    struct DraftProperties: Codable {
        let messageGUID: String
        let name: String
    }

    var contentPreview: MessagePreview.Content {
        .init(
            processed: .photo(image: AsyncContentProvider<UIImage>(value: self.image)),
            raw: .init(type: ImageContent.messageType, content: self.messageGUID, meta: [:])
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
        guard let data = cacheService.retrieve(file: FileInfo(uuid: props.messageGUID)) else {
            return nil
        }

        guard let image = UIImage(data: data) else {
            return nil
        }

        let sender = ImageContentSender(image: image, name: props.name, messageContent: data)
        sender.messageGUID = props.messageGUID
        
        return sender
    }

    func makeDraftAttachment(with dependencies: ContentSenderDependencies) -> DraftAttachment? {
        let encoder = JSONEncoder()

        self.cacheData(self.messageContent, with: dependencies)

        let properties = DraftProperties(messageGUID: self.messageGUID, name: self.name)

        guard let props = try? encoder.encode(properties),
              let propsString = String(data: props, encoding: .utf8) else {
            return nil
        }

        return DraftAttachment(type: Self.draftAttachmentType, properties: propsString)
    }

    @discardableResult
    private func cacheData(_ data: Data?, with dependencies: ContentSenderDependencies) -> URL? {
        guard let data = data else {
            return nil
        }

        let file = FileInfo(uuid: self.messageGUID)
        return dependencies.cacheService.save(file: file, data: data)
    }
}
