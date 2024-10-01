import Foundation

final class ContactContentSender: ContentSender {
    var content: MessageContent? {
        guard let content = self.messageContent.asVCard() else {
            return nil
        }

        return ContactContent(content: .local(content: content))
    }

    private(set) var messageGUID: String = UUID().uuidString
    private let messageContent: ContactItem

    init(messageContent: ContactItem) {
        self.messageContent = messageContent
    }

    var filename: String {
        "contact_\(self.messageGUID)"
    }

    func send(
        channelID: String,
        using dependencies: ContentSenderDependencies,
        updates: @escaping (MessageContent, ContentMeta) -> Void,
        completion: @escaping (Result<MessageContent, Swift.Error>) -> Void
    ) {
        let guid = self.messageGUID
        let filename = self.filename

        guard let content = self.content as? ContactContent else {
            completion(.failure(Error.invalidContact))
            return
        }

        let contentMeta = ContentMeta(
            contactName: self.messageContent.fullName,
            contactPhone: self.messageContent.phone ?? "–"
        )

        updates(content, contentMeta)
        
        guard let data = self.messageContent.asVCard() else {
            return
        }

        dependencies.fileService.uploadImmediate(
            filename: filename,
            data: data,
            mimeType: .vcard
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let files):
                if let file = files.first, file.name.starts(with: filename), file.error == nil {
                    let remoteContent = ContactContent(content: .remote(path: file.path))
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
    }

    // MARK: - Error

    enum Error: Swift.Error {
        case invalidUploading
        case invalidContact
    }
}

extension ContactContentSender {
    static var draftAttachmentType: String { "CONTACT" }

    struct DraftProperties: Codable {
        let messageGUID: String
        let contactCachedFileName: String
        let name: String
    }

    var contentPreview: MessagePreview.Content {
        .init(
            processed: .contact(name: self.messageContent.fullName),
            raw: .init(type: ContactContent.messageType, content: self.messageGUID, meta: [:])
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
        guard let data = cacheService.retrieve(cacheKey: props.contactCachedFileName) else {
            return nil
        }

        guard let contact = ContactItem.init(data: data) else {
            return nil
        }

        let sender = ContactContentSender(messageContent: contact)
        sender.messageGUID = props.messageGUID

        return sender
    }

    func makeDraftAttachment(with dependencies: ContentSenderDependencies) -> DraftAttachment? {
        let encoder = JSONEncoder()

        let cacheKey = "contact_\(self.messageGUID)"

        let cacheService = dependencies.cacheService
        if let data = self.messageContent.asVCard() {
            cacheService.save(cacheKey: cacheKey, data: data)
        }

        let properties = DraftProperties(
            messageGUID: self.messageGUID,
            contactCachedFileName: cacheKey,
            name: self.filename
        )

        guard let props = try? encoder.encode(properties),
              let propsString = String(data: props, encoding: .utf8) else {
            return nil
        }

        return DraftAttachment(type: Self.draftAttachmentType, properties: propsString)
    }
}
