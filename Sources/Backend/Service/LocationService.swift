import Foundation
import CoreLocation

typealias LocationServiceFetchCompletion = (LocationServiceResult) -> Void

enum LocationServiceResult {
    case success(CLLocationCoordinate2D)
    case error(LocationServiceError)
}

/// An enumeration representing the different errors that can occur when using the location services
enum LocationServiceError: Error, Equatable {
    /// Indicates that the location services are not allowed by the user
    case notAllowed
    /// Indicates that the location services are restricted and cannot be used
    case restricted
    /// Indicates that a system error occurred. The associated value is the underlying error
    case systemError(Error)

    /// Equatable conformance for LocationServiceError
    ///
    /// - Parameters:
    ///   - lhs: A `LocationServiceError` instance on the left-hand side of the comparison.
    ///   - rhs: A `LocationServiceError` instance on the right-hand side of the comparison.
    /// - Returns: A Boolean value indicating whether the two `LocationServiceError` instances are considered equal.
    static func == (lhs: LocationServiceError, rhs: LocationServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.notAllowed, .notAllowed):
            return true
        case (.restricted, .restricted):
            return true
        case (.systemError(let lhsError), .systemError(let rhsError)):
            return (lhsError as NSError).domain == (rhsError as NSError).domain &&
            (lhsError as NSError).code == (rhsError as NSError).code
        default:
            return false
        }
    }
}

protocol LocationServiceProtocol: AnyObject {
    /// Last fetched location
    var lastLocation: CLLocation? { get }

    /// Get current location of the device once
    func fetchLocation(completion: @escaping LocationServiceFetchCompletion)

    /// Continuously get current location of the device
    func startGettingLocation(completion: @escaping LocationServiceFetchCompletion)

    /// Stop getting location of the device.
    /// Should be used after calling `startGettingLocation(completion:)`
    func stopGettingLocation()

    /// Distance in meters from the last fetched location
    func distanceFromLocation(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance?

    /// Reverse geocoding for coordinate
    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Swift.Error>) -> Void)
}

final class LocationService: CLLocationManager, LocationServiceProtocol {
    enum Settings {
        static let accuracy = kCLLocationAccuracyBest
        static let distanceFilter: CLLocationDistance = 50
    }

    private var oneTimeFetchCompletion: LocationServiceFetchCompletion?
    private var continuousFetchCompletion: LocationServiceFetchCompletion?

    private lazy var geocoder = CLGeocoder()
    private static let geocodingQueue = DispatchQueue(label: "LocationService.geocoding")
    private let geocodingSemaphore = DispatchSemaphore(value: 1)

    private(set) var isUpdatingLocation = false

    private(set) var lastLocation: CLLocation?

    override init() {
        super.init()

        self.desiredAccuracy = Settings.accuracy
        self.distanceFilter = Settings.distanceFilter
        self.delegate = self
    }

    private var forcedLocation: CLLocation? {
        guard
            let latitude = doubleValue(forUserDefaultsKey: "TECHNOLAB_FORCED_LOCATION_LATITUDE"),
            let longitude = doubleValue(forUserDefaultsKey: "TECHNOLAB_FORCED_LOCATION_LONGITUDE")
        else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    private func doubleValue(forUserDefaultsKey key: String) -> Double? {
        guard UserDefaults.standard.object(forKey: key) != nil else { return nil }
        return UserDefaults.standard.double(forKey: key)
    }

    func fetchLocation(completion: @escaping LocationServiceFetchCompletion) {
        if let forcedLocation = self.forcedLocation {
            self.lastLocation = forcedLocation
        }

        if let lastLocation {
            completion(.success(lastLocation.coordinate))
            return
        }

        self.oneTimeFetchCompletion = completion
        self.requestWhenInUseAuthorization()
        self.startUpdatingLocation()
    }

    func startGettingLocation(completion: @escaping LocationServiceFetchCompletion) {
        continuousFetchCompletion = completion
        requestAlwaysAuthorization()
        startUpdatingLocation()
        isUpdatingLocation = true
    }

    func stopGettingLocation() {
        stopUpdatingLocation()
        continuousFetchCompletion = nil
        isUpdatingLocation = false
    }

    func distanceFromLocation(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return self.lastLocation?.distance(from: location)
    }

    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Swift.Error>) -> Void) {
        Self.geocodingQueue.async {
            self.geocodingSemaphore.wait()

            self.geocoder.reverseGeocodeLocation(location) { (placemark, error) in
                defer {
                    self.geocodingSemaphore.signal()
                }

                if let error = error {
                    return completion(.failure(error))
                }

                let name = placemark?.first?.addressDictionary?["Name"] as? String
                let city = placemark?.first?.addressDictionary?["City"] as? String
                let country = placemark?.first?.addressDictionary?["Country"] as? String
                let address = [name, city, country].compactMap({ $0 }).joined(separator: ", ")

                guard !address.isEmpty else {
                    return completion(.failure(Error.invalidPlacemark))
                }

                completion(.success(address))
            }
        }
    }

    // MARK: - Errors

    enum Error: Swift.Error {
        case invalidPlacemark
    }

    // MARK: - Private

    private func update(with result: LocationServiceResult) {
        self.oneTimeFetchCompletion?(result)
        self.continuousFetchCompletion?(result)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var location = locations.last
        
        if let forcedLocation = self.forcedLocation {
            location = forcedLocation
        }

        guard let location else {
            return
        }

        self.lastLocation = location
        self.update(with: .success(location.coordinate))

        self.oneTimeFetchCompletion = nil
        if self.continuousFetchCompletion == nil {
            self.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            self.update(with: .error(.restricted))
        case .denied:
            self.update(with: .error(.notAllowed))
        // Debug only cases
        case .notDetermined:
            log(sender: self, "location service: location status not determined")
        case .authorizedAlways, .authorizedWhenInUse:
            log(sender: self, "location service: location status is OK")
        @unknown default:
            log(sender: self, "location service: unknown authorization status")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        switch error._code {
        case 1:
            self.stopUpdatingLocation()
            self.update(with: .error(.notAllowed))
        default:
            self.update(with: .error(.systemError(error)))
        }
    }
}

final class DummyLocationService: LocationServiceProtocol {
    var lastLocation: CLLocation?
    func fetchLocation(completion: @escaping LocationServiceFetchCompletion) {}
    func startGettingLocation(completion: @escaping LocationServiceFetchCompletion) {}
    func stopGettingLocation() {}
    func distanceFromLocation(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? { nil }
    func reverseGeocode(location: CLLocation, completion: @escaping (Result<String, Error>) -> Void) {}
}
