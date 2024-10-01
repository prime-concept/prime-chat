import XCTest
import CoreLocation
@testable import ChatSDK

class LocationServiceTests: XCTestCase {

    var locationService: LocationService!

    override func setUp() {
        super.setUp()
        locationService = LocationService()
    }

    override func tearDown() {
        locationService = nil
        super.tearDown()
    }

    func testFetchLocationSuccess() {
        // Arrange
        let expectation = expectation(description: "fetchLocation")

        // Act
        locationService.fetchLocation { result in

            // Assert
            switch result {
            case .success(let coordinate):
                XCTAssertEqual(coordinate.latitude, 11.1111, accuracy: 0.001)
                XCTAssertEqual(coordinate.longitude, 22.2222, accuracy: 0.001)
            case .error:
                XCTFail("Expected success, got error")
            }
            expectation.fulfill()
        }

        locationService.delegate?.locationManager?(
            CLLocationManager(),
            didUpdateLocations: [CLLocation(
                latitude: 11.1111,
                longitude: 22.2222
            )]
        )
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testFetchLocationError() {
        let expectation = expectation(description: "fetchLocation")
        locationService.fetchLocation { result in
            switch result {
            case .success:
                XCTFail("Expected error, got success")
            case .error(let error):
                XCTAssertEqual(error, .notAllowed)
            }
            expectation.fulfill()
        }
        locationService.delegate?.locationManager?(
            CLLocationManager(),
            didFailWithError: NSError(
                domain: kCLErrorDomain,
                code: CLError.denied.rawValue,
                userInfo: nil
            )
        )
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testStartGettingLocation() {
        let expectation = self.expectation(description: "startGettingLocation")
        expectation.expectedFulfillmentCount = 2 // Expecting two location updates

        var updateCount = 0
        let coordinates = [
            CLLocationCoordinate2D(latitude: 11.1111, longitude: 22.2222),
            CLLocationCoordinate2D(latitude: 33.3333, longitude: 44.4444)
        ]

        locationService.startGettingLocation { result in
            switch result {
            case .success(let coordinate):
                let expectedCoordinate = coordinates[updateCount]
                XCTAssertEqual(coordinate.latitude, expectedCoordinate.latitude, accuracy: 0.001)
                XCTAssertEqual(coordinate.longitude, expectedCoordinate.longitude, accuracy: 0.001)
                updateCount += 1
            case .error:
                XCTFail("Expected success, got error")
            }
            expectation.fulfill()
        }

        locationService.delegate?.locationManager?(
            CLLocationManager(),
            didUpdateLocations: [CLLocation(
                latitude: coordinates[0].latitude,
                longitude: coordinates[0].longitude
            )]
        )
        locationService.delegate?.locationManager?(
            CLLocationManager(),
            didUpdateLocations: [CLLocation(
                latitude: coordinates[1].latitude,
                longitude: coordinates[1].longitude
            )]
        )

        XCTAssertTrue(locationService.isUpdatingLocation)

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testStopGettingLocation() {
        // Arrange
        locationService.startGettingLocation { _ in }

        // Act
        locationService.stopGettingLocation()

        // Assert
        XCTAssertFalse(locationService.isUpdatingLocation)
    }

    func testDistanceFromLocation() {
        // Arrange
        locationService.delegate?.locationManager?(
            CLLocationManager(),
            didUpdateLocations: [CLLocation(
                latitude: 11.1111,
                longitude: 22.2222
            )]
        )

        // Act
        let distance = locationService.distanceFromLocation(
            to: CLLocationCoordinate2D(
                latitude: 33.3333,
                longitude: 44.4444
            )
        )

        // Assert
        XCTAssertNotNil(distance)
    }

    func testReverseGeocodeSuccess() {
        let expectation = expectation(description: "reverseGeocode")
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        locationService.reverseGeocode(location: location) { result in
            switch result {
            case .success(let address):
                XCTAssertEqual(address, "10 S Van Ness Ave, San Francisco, United States")
            case .failure:
                XCTFail("Expected success, got error")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }

    func testReverseGeocodeFailure() {
        let expectation = expectation(description: "reverseGeocode")
        let location = CLLocation(latitude: 90.0000, longitude: 00.0000)
        locationService.reverseGeocode(location: location) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, got success")
            case .failure(let error):
                XCTAssertEqual((error as NSError).domain, kCLErrorDomain)
                XCTAssertEqual((error as NSError).code, CLError.geocodeFoundNoResult.rawValue)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
