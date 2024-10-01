import XCTest
import Network
@testable import ChatSDK

final class NetworkMonitorTests: XCTestCase {

    func testSingletonInstance() {
        let instance1 = NetworkMonitor.shared
        let instance2 = NetworkMonitor.shared
        XCTAssert(instance1 === instance2, "NetworkMonitor.shared should return the same instance")
    }

    func testInitialConnectionState() {
        let monitor = NetworkMonitor.shared
        XCTAssertFalse(monitor.isConnected, "Initial isConnected should be false")
    }

    func testPathUpdateHandler() {
        let monitor = NetworkMonitor.shared

        let expectation = expectation(description: "Path Update Handler should be called")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)

        XCTAssertTrue(monitor.isConnected, "isConnected should be true when path status is .satisfied")
    }
}
