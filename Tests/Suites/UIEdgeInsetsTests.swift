@testable import ChatSDK

import XCTest

final class UIEdgeInsetsTests: XCTestCase {
    
    func test_negated_positiveValues() {
        let negatedInsets = UIEdgeInsets(top: 1, left: 2, bottom: 3, right: 4).negated()
        
        XCTAssertEqual(negatedInsets.top, -1)
        XCTAssertEqual(negatedInsets.left, -2)
        XCTAssertEqual(negatedInsets.bottom, -3)
        XCTAssertEqual(negatedInsets.right, -4)
    }
    
    func test_negated_mixedValues() {
        let negatedInsets = UIEdgeInsets(top: 16, left: -24, bottom: -32, right: 48).negated()
        
        XCTAssertEqual(negatedInsets.top, -16)
        XCTAssertEqual(negatedInsets.left, 24)
        XCTAssertEqual(negatedInsets.bottom, 32)
        XCTAssertEqual(negatedInsets.right, -48)
    }
    
    func test_negated_zeroValues() {
        let negatedInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0).negated()
        
        XCTAssertEqual(negatedInsets.top, 0)
        XCTAssertEqual(negatedInsets.left, 0)
        XCTAssertEqual(negatedInsets.bottom, 0)
        XCTAssertEqual(negatedInsets.right, 0)
    }
    
}
