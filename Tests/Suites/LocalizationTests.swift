//

import XCTest
@testable import ChatSDK

final class LocalizationTests: XCTestCase {

    func testLocalizableExistKey() {
        // Prepare
        let key = "location"
        
        // Action
        let value = "location".localized
        
        // Assert
        XCTAssertNotEqual(key, value)
    }
    
    func testLocalizableNonExistKey() {
        // Preapare
        let key = "nonExistKey"
        
        // Action
        let value = "nonExistKey".localized
        
        // Assert
        XCTAssertEqual(key, value)
    }

    func testWorngLocalizableBundle() {
        // Prepare
        let key = "location"
        
        // Action
        let value = NSLocalizedString(
            key,
            tableName: nil,
            bundle: Bundle.main,
            value: "",
            comment: ""
        )
        
        // Assert
        XCTAssertEqual(key, value)
    }
}
