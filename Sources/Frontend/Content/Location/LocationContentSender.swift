import Foundation
import CoreLocation

final class LocationContentSender: ContentSender {
    var content: MessageContent? {
        LocationContent(content: .local(point: self.point))
    }

    private let point: CLLocationCoordinate2D

    private(set) var messageGUID: String = UUID().uuidString

    init(point: CLLocationCoordinate2D) {
        self.point = point
    }

    func send(
        channelID: String,
        using dependencies: ContentSenderDependencies,
        updates: @escaping (MessageContent, ContentMeta) -> Void,
        completion: @escaping (Result<MessageContent, Swift.Error>) -> Void
    ) {
        let contentMeta = ContentMeta(
            locationLatitude: point.latitude,
            locationLongitude: point.longitude
        )

        guard let locationFileData = self.locationData,
              let content = self.content as? LocationContent else {
            completion(.failure(Error.invalidLocationEncoding))
            return
        }

        updates(content, contentMeta)

        let guid = self.messageGUID
        let filename = "location_\(self.messageGUID)"

        dependencies.fileService.uploadImmediate(
            filename: filename,
            data: locationFileData,
            mimeType: .plain
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let files):
                if let file = files.first, file.name.starts(with: filename), file.error == nil {
                    let remoteContent = LocationContent(content: .remote(path: file.path))
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

    private var locationData: Data? {
        let point = self.point

        let locationFile = StorageLocationWrapper(
            longitude: point.longitude,
            latitude: point.latitude
        )

        guard
            let locationFileData = try? JSONEncoder().encode(locationFile),
            content is LocationContent
        else {
            return nil
        }

        return locationFileData
    }

    // MARK: - Error

    enum Error: Swift.Error {
        case invalidLocationEncoding
        case invalidUploading
    }
}

extension LocationContentSender {
    static var draftAttachmentType: String { "LOCATION" }

    struct DraftProperties: Codable {
        let messageGUID: String
        let locationCachedFileName: String
        let name: String
    }

    var contentPreview: MessagePreview.Content {
        .init(
            processed: .geo,
            raw: .init(type: LocationContent.messageType, content: self.messageGUID, meta: [:])
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
        guard let data = cacheService.retrieve(cacheKey: props.locationCachedFileName),
              let wrapper = try? ChatJSONDecoder().decode(StorageLocationWrapper.self, from: data) else {
            return nil
        }

        let point = CLLocationCoordinate2DMake(wrapper.latitude, wrapper.longitude)
        let sender = LocationContentSender(point: point)
        sender.messageGUID = props.messageGUID
        return sender
    }

    func makeDraftAttachment(with dependencies: ContentSenderDependencies) -> DraftAttachment? {
        let encoder = JSONEncoder()

        let cacheKey = "location_\(self.messageGUID)"

        let cacheService = dependencies.cacheService
        if let data = self.locationData {
            cacheService.save(cacheKey: cacheKey, data: data)
        }

        let properties = DraftProperties(
            messageGUID: self.messageGUID,
            locationCachedFileName: cacheKey,
            name: self.messageGUID
        )

        guard let props = try? encoder.encode(properties),
              let propsString = String(data: props, encoding: .utf8) else {
            return nil
        }

        return DraftAttachment(type: Self.draftAttachmentType, properties: propsString)
    }
}
