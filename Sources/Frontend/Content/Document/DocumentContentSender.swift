import Foundation

final class DocumentContentSender: ContentSender {
    var content: MessageContent? {
        let url = self.messageContentURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let fileName = url.lastPathComponent
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? Double)

        return DocumentContent(
            messageGUID: self.messageGUID,
            content: .init(path: url.path, progress: nil, name: fileName, size: size)
        )
    }

    private var messageContentURL: URL {
        self.cachedContentURL ?? self.sourceContentURL
    }

    private let sourceContentURL: URL
    private var cachedContentURL: URL?

    private(set) var messageGUID: String = UUID().uuidString

    init(sourceContentURL: URL) {
        self.sourceContentURL = sourceContentURL
    }

    func send(
        channelID: String,
        using dependencies: ContentSenderDependencies,
        updates: @escaping (MessageContent, ContentMeta) -> Void,
        completion: @escaping (Result<MessageContent, Swift.Error>) -> Void
    ) {
        var documentData: Data?

        if self.cachedContentURL == nil,
           let data = try? Data(contentsOf: self.sourceContentURL) {
            documentData = data
            self.cachedContentURL = self.cacheData(data, with: dependencies)
        }

        let guid = self.messageGUID
        let url = self.messageContentURL

        guard var content = self.content as? DocumentContent,
              let data = documentData ?? (try? Data(contentsOf: url)) else {
            completion(.failure(Error.invalidDocument))
            return
        }

        let fileName = url.lastPathComponent
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? Double)

        let contentMeta = ContentMeta(
            documentSize: size,
            documentName: fileName
        )

        content.content.progress = 0
        updates(content, contentMeta)

        dependencies.fileService.uploadImmediate(
            filename: fileName,
            data: data,
            mimeType: .unknown,
            progress: { progress in
                let localContent = DocumentContent(
                    content: .init(path: nil, progress: progress, name: fileName, size: size)
                )
                updates(localContent, contentMeta)
            },
            completion: { result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let files):
                    if let file = files.first, file.name.starts(with: fileName), file.error == nil {
                        let remoteContent = DocumentContent(
                            messageGUID: guid,
                            content: .init(path: file.path, progress: 1.0, name: fileName, size: size)
                        )
                        dependencies.sendMessageService.send(
                            guid: guid,
                            channelID: channelID,
                            content: remoteContent,
                            contentMeta: contentMeta,
                            replyTo: nil
                        ) { result in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success:
                                completion(.success(remoteContent))
                            }
                        }
                    } else {
                        completion(.failure(Error.invalidUploading))
                    }
                }
            }
        )
    }

    // MARK: - Error

    enum Error: Swift.Error {
        case invalidDocument
        case invalidUploading
    }
}

extension DocumentContentSender {
    static var draftAttachmentType: String { "DOCUMENT" }

    struct DraftProperties: Codable {
        let messageGUID: String
        let messageContentURL: URL
        let fileName: String
    }

    var contentPreview: MessagePreview.Content {
        let url = self.messageContentURL
        let fileName = url.lastPathComponent
        let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[FileAttributeKey.size] as? Double)

        return .init(
            processed: .document(name: fileName, size: size),
            raw: .init(type: DocumentContent.messageType, content: fileName, meta: [:])
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
        
        var file = FileInfo(uuid: props.messageGUID)
        file.fileName = props.fileName

        guard let url = dependencies.cacheService.exists(file: file) else {
            return nil
        }

        let sender = DocumentContentSender(sourceContentURL: url)
        sender.messageGUID = props.messageGUID
        
        return sender
    }

    func makeDraftAttachment(with dependencies: ContentSenderDependencies) -> DraftAttachment? {
        let encoder = JSONEncoder()

        var documentData: Data?

        if self.cachedContentURL == nil,
           let data = try? Data(contentsOf: self.sourceContentURL) {
            documentData = data
            self.cachedContentURL = self.cacheData(data, with: dependencies)
        }

        let guid = self.messageGUID

        let data = documentData ?? (try? Data(contentsOf: self.messageContentURL))
        if data == nil {
            return nil
        }

        let properties = DraftProperties(
            messageGUID: guid,
            messageContentURL: self.messageContentURL,
            fileName: self.messageContentURL.lastPathComponent
        )

        guard let props = try? encoder.encode(properties),
              let propsString = String(data: props, encoding: .utf8) else {
            return nil
        }

        return DraftAttachment(type: Self.draftAttachmentType, properties: propsString)
    }

    private var fileInfo: FileInfo {
        var file = FileInfo(uuid: self.messageGUID)
        file.fileName = self.messageContentURL.lastPathComponent
        return file
    }

    private func cacheData(_ data: Data?, with dependencies: ContentSenderDependencies) -> URL? {
        guard let data = data else {
            return nil
        }

        return dependencies.cacheService.save(file: self.fileInfo, data: data)
    }
}
