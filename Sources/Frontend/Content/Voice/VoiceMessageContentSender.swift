import Foundation

final class VoiceMessageContentSender: ContentSender {
    var content: MessageContent? {
        VoiceMessageContent(
            messageGUID: self.messageGUID,
            content: .local(content: self.messageContent)
        )
    }

    private let messageContent: Data

    private(set) var messageGUID: String = UUID().uuidString

    init(messageContent: Data) {
        self.messageContent = messageContent
    }

    func send(
        channelID: String,
        using dependencies: ContentSenderDependencies,
        updates: @escaping (MessageContent, ContentMeta) -> Void,
        completion: @escaping (Result<MessageContent, Swift.Error>) -> Void
    ) {
        let guid = self.messageGUID
        let data = self.messageContent
        let filename = "voicemessage_\(guid).m4a"
        guard let content = self.content else {
            return
        }

        let meta = ContentMeta(documentName: filename)
        updates(content, meta)

        var file = FileInfo(uuid: guid)
        file.fileName = filename
        _ = dependencies.cacheService.save(file: file, data: data)

        dependencies.fileService.uploadImmediate(
            filename: filename,
            data: data,
            mimeType: .audio
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let files):
                if let file = files.first, file.name.starts(with: filename), file.error == nil {
                    let voiceMessageFile = FileInfo(uploadedFile: file)
                    let remoteContent = VoiceMessageContent(
                        messageGUID: guid,
                        content: .remote(file: voiceMessageFile)
                    )
                    dependencies.sendMessageService.send(
                        guid: guid,
                        channelID: channelID,
                        content: remoteContent,
                        contentMeta: nil,
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
    }

    // MARK: - Error

    enum Error: Swift.Error {
        case invalidUploading
    }
}

extension VoiceMessageContentSender {
    static var draftAttachmentType: String { "VOICE" }

    struct DraftProperties: Codable {
        let messageGUID: String
    }

    var contentPreview: MessagePreview.Content {
        .init(
            processed: .voice,
            raw: .init(type: VoiceMessageContent.messageType, content: self.messageGUID, meta: [:])
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

        let cacheFile = FileInfo(uuid: props.messageGUID, defaultExtension: "m4a")
        let cacheService = dependencies.cacheService
        guard let data = cacheService.retrieve(file: cacheFile) else {
            return nil
        }

        let sender = VoiceMessageContentSender(messageContent: data)
        sender.messageGUID = props.messageGUID
        return sender
    }

    func makeDraftAttachment(with dependencies: ContentSenderDependencies) -> DraftAttachment? {
        let encoder = JSONEncoder()

        self.cacheData(self.messageContent, with: dependencies)

        let properties = DraftProperties(messageGUID: self.messageGUID)

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

        let file = FileInfo(uuid: self.messageGUID, defaultExtension: "m4a")
        return dependencies.cacheService.save(file: file, data: data)
    }
}
