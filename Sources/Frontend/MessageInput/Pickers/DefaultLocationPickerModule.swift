import UIKit
import CoreLocation
import MapKit

final class DefaultLocationPickerModule: BaseLocationViewController, PickerModule {
    static var listItem = Optional(PickerListItem(icon: UIImage(), title: "location".localized))

    static var resultContentTypes: [MessageContent.Type] {
        return [LocationContent.self]
    }

    weak var pickerDelegate: PickerDelegate?

    var viewController: UIViewController {
        return self
    }

    private let dependencies: PickerModuleDependencies

    init(dependencies: PickerModuleDependencies) {
        self.dependencies = dependencies

        super.init(presentationType: .pick)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = Self.listItem?.title
    }

    override func focusOnUserLocation(animated: Bool) {
        self.dependencies.locationService.fetchLocation { [weak self] result in
            switch result {
            case .success(let coordinate):
                self?.focusOnLocation(coordinate: coordinate, animated: animated)
            case .error:
                break
            }
        }
    }

    override func requestDismissAndSend() {
        let coordinate = self.mapView.centerCoordinate

        self.dismiss(animated: true) { [weak pickerDelegate] in
            pickerDelegate?.sendContent(sender: LocationContentSender(point: coordinate))
        }
    }

    override func requestGeocode(location: CLLocation, completion: @escaping (String) -> Void) {
        self.dependencies.locationService.reverseGeocode(location: location) { result in
            switch result {
            case .success(let name):
                completion(name)
            case .failure:
                completion("unknown.location".localized)
            }
        }
    }
}
