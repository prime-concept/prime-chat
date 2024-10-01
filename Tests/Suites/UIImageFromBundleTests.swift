@testable import ChatSDK

import XCTest

final class UIImageFromBundleTests: XCTestCase {
    
    func test_fromBundle_existingImage() {
        let image = UIImage._fromBundle(name: "location_pin")
        
        XCTAssertNotNil(image)
    }
    
    func test_fromBundle_nonexistentImage() {
        let image = UIImage._fromBundle(name: "TEST_nonexistent_image")
        
        XCTAssertNil(image)
    }
    
}
