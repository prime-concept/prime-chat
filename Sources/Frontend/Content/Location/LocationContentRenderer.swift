import UIKit
import CoreLocation

final class LocationContentRenderer: ContentRenderer {
    static let messageContentType: MessageContent.Type = LocationContent.self

    static var messageModelType: MessageModel.Type {
        return MessageContainerModel<LocationContentView>.self
    }

    private let content: LocationContent
    private let contentMeta: ContentMeta
    private let actions: ContentRendererActions
    private let dependencies: ContentRendererDependencies

    private var onContentOpened: MessageContentOpeningCompletion?

    private var locationWrapper: StorageLocationWrapper?

    private var locationFromFile: CLLocationCoordinate2D? {
        self.locationWrapper.flatMap { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    private var locationFromMeta: CLLocationCoordinate2D? {
        if let lat = self.contentMeta.locationLatitude, let lng = self.contentMeta.locationLongitude {
            return CLLocationCoordinate2D(latitude: lat, longitude: lng)
        }
        return nil
    }

    private var locationLocal: CLLocationCoordinate2D? {
        let content = self.content.content
        if case .local(let coordinate) = content {
            return CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        return nil
    }

    private init(
        content: LocationContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) {
        self.content = content
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
        guard let content = content as? LocationContent else {
            fatalError("Incorrect content type")
        }

        // Swift.print("WILL MAKE FOR GUID: \(content.messageGUID ?? "") \(Self.self)")

        return LocationContentRenderer(
            content: content,
            contentMeta: contentMeta,
            actions: actions,
            dependencies: dependencies
        )
    }

    func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel {
        var actions = self.actions
        actions.openContent = { completion in
            if self.anyLocation != nil {
                self.openLocation()
                completion()
                return
            }
            self.onContentOpened = completion
        }

        return MessageContainerModel<LocationContentView>(
            uid: uid,
            meta: meta,
            contentControlValue: 0,
            shouldCalculateHeightOnMainThread: false,
            actions: self.actions,
            contentConfigurator: { view in
                view.onTap = { [weak self] in
                    self?.openLocation()
                }

                if let location = self.anyLocation {
                    view.update(coordinate: location)
                    return
                }

                // TODO @v.kiryukhin: potentially race condition, avoid request duplication
                self.downloadLocation {
                    self.locationFromFile.flatMap { view.update(coordinate: $0) }
                }
            },
            heightCalculator: { _, _ in
                LocationContentView.height
            }
        )
    }

    func preview() -> MessagePreview.ProcessedContent? {
        .geo
    }

    // MARK: - Private

    private var anyLocation: CLLocationCoordinate2D? {
        self.locationLocal ?? self.locationFromMeta ?? self.locationFromFile
    }

    private func openLocation() {
        defer {
            self.onContentOpened?()
            self.onContentOpened = nil
        }

        let locationService = self.dependencies.locationService
        let fileService = self.dependencies.fileService

        guard let location = self.anyLocation else {
            return
        }

        let controller = LocationViewController(
            coordinate: location,
            locationService: locationService
        )
        let navigationController = StylizedNavigationContoller(rootViewController: controller)
        self.dependencies.chatDelegate?.requestPresentation(for: navigationController, completion: nil)
    }

    private func downloadLocation(completion: (() -> Void)? = nil) {
        guard case .remote(let path) = self.content.content,
              let file = FileInfo(remotePath: path) else {
            completion?()
            return
        }

        let fileService = self.dependencies.fileService

        fileService.downloadAndDecode(
            file: file,
            skipCache: false,
            onMainQueue: false
        ) { [weak self] (locationWrapper: StorageLocationWrapper?) in
            guard let locationWrapper else {
                delay(1) {
                    self?.downloadLocation(completion: completion)
                }
                return
            }
            self?.locationWrapper = locationWrapper
            completion?()
        }
    }
}
