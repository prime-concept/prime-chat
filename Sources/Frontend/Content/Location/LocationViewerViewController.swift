import UIKit
import CoreLocation

final class LocationViewController: BaseLocationViewController {
    private let locationService: LocationServiceProtocol

    init(coordinate: CLLocationCoordinate2D, locationService: LocationServiceProtocol) {
        self.locationService = locationService

        super.init(presentationType: .fix(coordinate))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "location".localized
    }

    override func focusOnUserLocation(animated: Bool) {
        self.locationService.fetchLocation { [weak self] result in
            switch result {
            case .success(let coordinate):
                self?.focusOnLocation(coordinate: coordinate, animated: animated)
            case .error:
                break
            }
        }
    }

    override func requestGeocode(location: CLLocation, completion: @escaping (String) -> Void) {
        self.locationService.reverseGeocode(location: location) { result in
            switch result {
            case .success(let name):
                completion(name)
            case .failure:
                completion("unknown.location".localized)
            }
        }
    }
}
