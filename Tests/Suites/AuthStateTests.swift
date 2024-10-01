//
//  AuthStateTests.swift
//  
//
//  Created by Hayk Kolozyan on 23.05.24.
//

import XCTest

@testable import ChatSDK

final class AuthStateTests: XCTestCase {

    var sutAuthState: AuthState!

    override func setUp() {
        super.setUp()
        sutAuthState = AuthState(
            accessToken: "validToken",
            clientAppID: "clientID",
            deviceID: "deviceID",
            wsUniqueID: "wsID"
        )
    }

    override func tearDown() {
        sutAuthState = nil
        super.tearDown()
    }

    func testInitWithValidData() {
        // Assert
        XCTAssertEqual(sutAuthState.accessToken, "validToken")
        XCTAssertEqual(sutAuthState.clientAppID, "clientID")
        XCTAssertEqual(sutAuthState.deviceID, "deviceID")
        XCTAssertEqual(sutAuthState.wsUniqueID, "wsID")
        XCTAssertEqual(sutAuthState.bearerToken, "validToken")
    }

    func testInitWithNilData() {
        // Arrange
        let nilAuthState = AuthState(accessToken: nil, clientAppID: nil, deviceID: nil, wsUniqueID: nil)

        // Assert
        XCTAssertNil(nilAuthState.accessToken)
        XCTAssertNil(nilAuthState.clientAppID)
        XCTAssertNil(nilAuthState.deviceID)
        XCTAssertNil(nilAuthState.wsUniqueID)
        XCTAssertNil(nilAuthState.bearerToken)
    }

    func testDidRefreshTokenNotification() {
        // Arrange
        let notification = Notification(
            name: .didRefreshToken,
            object: nil,
            userInfo: ["access_token": "newValidToken"]
        )

        // Act
        NotificationCenter.default.post(notification)

        // Assert
        XCTAssertEqual(sutAuthState.accessToken, "newValidToken")
    }

    func testDidRefreshTokenNotificationWithNoToken() {
        // Arrange
        let notification = Notification(name: .didRefreshToken, object: nil, userInfo: nil)

        // Act
        NotificationCenter.default.post(notification)

        // Assert
        XCTAssertEqual(sutAuthState.accessToken, "validToken")
    }

    func testBearerToken() {
        // Arrange
        sutAuthState.accessToken = "newValidToken"

        // Assert
        XCTAssertEqual(sutAuthState.bearerToken, "newValidToken")
    }

    func testBearerTokenWhenAccessTokenIsNil() {
        // Arrange
        sutAuthState.accessToken = nil

        // Assert
        XCTAssertNil(sutAuthState.bearerToken)
    }
    
    func testPostIncorrectNotification() {
        // Act
        NotificationCenter.default.post(name: .didRefreshToken, object: nil, userInfo: ["wrong_key": "wrongValue"])

        // Assert
        XCTAssertEqual(sutAuthState.accessToken, "validToken")
    }

    func testPostIncorrectNotificationName() {
        // Act
        NotificationCenter.default.post(name: Notification.Name("didRefreshTokenn"), object: nil, userInfo: nil)

        // Assert
        XCTAssertEqual(sutAuthState.accessToken, "validToken")
    }

}
