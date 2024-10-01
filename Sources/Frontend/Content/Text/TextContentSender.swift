import Foundation

final class TextContentSender: ContentSender {
    private let text: String
    private let reply: ReplyPreview?

    private(set) var messageGUID: String = UUID().uuidString

    var replyPreview: ReplyPreview? {
        return self.reply
    }

    init(guid: String?, text: String, reply: ReplyPreview?) {
        self.messageGUID = guid ?? self.messageGUID
        self.text = text
        self.reply = reply
    }
    
    var content: MessageContent? {
        TextContent(string: self.text)
    }
    
    func send(
        channelID: String,
        using dependencies: ContentSenderDependencies,
        updates: @escaping (MessageContent, ContentMeta) -> Void,
        completion: @escaping (Result<MessageContent, Error>) -> Void
    ) {
        let content = TextContent(string: self.text)

        updates(content, ContentMeta())

        dependencies.sendMessageService.send(
            guid: self.messageGUID,
            channelID: channelID,
            content: content,
            contentMeta: nil,
            replyTo: self.reply?.guid
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                completion(.success(content))
            }
        }
    }
}

extension TextContentSender {
    static var draftAttachmentType: String { "TEXT" }

    struct DraftProperties: Codable {
        let guid: String
        let text: String
        let replyPreview: ReplyPreview?
    }

    var contentPreview: MessagePreview.Content {
        .init(
            processed: .text(self.text),
            raw: .init(type: TextContent.messageType, content: self.messageGUID, meta: [:])
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

        return TextContentSender(guid: props.guid, text: props.text, reply: props.replyPreview)
    }

    func makeDraftAttachment(with dependencies: ContentSenderDependencies) -> DraftAttachment? {
        let encoder = JSONEncoder()

        let cacheKey = "text_\(self.messageGUID)"

        let cacheService = dependencies.cacheService

        let properties = DraftProperties(
            guid: self.messageGUID,
            text: self.text,
            replyPreview: self.replyPreview
        )

        guard let data = try? encoder.encode(properties),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        cacheService.save(cacheKey: cacheKey, data: data)

        return DraftAttachment(type: Self.draftAttachmentType, properties: string)
    }
}
