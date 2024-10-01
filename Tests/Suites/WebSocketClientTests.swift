//
//  WebSocketClientTests.swift
//
//
//  Created by Hayk Kolozyan on 29.05.24.
//

import XCTest
@testable import ChatSDK

class WebSocketClientTests: XCTestCase {

    var webSocketProtocolMock: WebSocketProtocolMock!
    var authStateMock: AuthStateProtocolMock!

    var sutWebSocketClient: WebSocketClient!

    override func setUp() {
        super.setUp()

        authStateMock = AuthStateProtocolMock()
        authStateMock.accessToken = "testAccessToken"
        authStateMock.clientAppID = "testClientAppID"
        authStateMock.deviceID = "testDeviceID"
        authStateMock.wsUniqueID = "testWsUniqueID"

        webSocketProtocolMock = WebSocketProtocolMock()
        sutWebSocketClient = WebSocketClient(
            baseURL: URL(string: "https://example.com")!,
            authState: authStateMock,
            socket: webSocketProtocolMock
        )
    }

    // MARK: - isConnected

    func testIsConnected() {

        // Arrange

        webSocketProtocolMock.underlyingIsConnected = true

        // Assert

        XCTAssertTrue(sutWebSocketClient.isConnected)
    }

    // MARK: - Connection

    func testConnection() {

        // Act

        sutWebSocketClient.connect()

        // Assert

        XCTAssertTrue(webSocketProtocolMock.connectVoidCalled)
        XCTAssertEqual(webSocketProtocolMock.connectVoidCallsCount, 1)
    }

    // MARK: - Disconnection

    func testDisconnection() {

        // Act

        sutWebSocketClient.disconnect()

        // Assert

        XCTAssertTrue(webSocketProtocolMock.disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidCalled)
        XCTAssertEqual(webSocketProtocolMock.disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidCallsCount, 1)
        XCTAssertNil(webSocketProtocolMock.disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidReceivedArguments?.forceTimeout)
        XCTAssertEqual(webSocketProtocolMock.disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidReceivedArguments?.closeCode, 1000)
    }

    // MARK: - onConnect

    func testOnConnect() {

        // Arrange

        let expectation = expectation(description: ".onConnect should be called")

        var isOnConnectCalled = false

        sutWebSocketClient.onConnect = {
            isOnConnectCalled = true
            expectation.fulfill()
        }

        // Act

        sutWebSocketClient.connect()
        webSocketProtocolMock.onConnect?()
        waitForExpectations(timeout: 5, handler: nil)

        // Assert

        XCTAssertTrue(isOnConnectCalled)
        XCTAssertTrue(webSocketProtocolMock.connectVoidCalled)
    }

    func testOnConnectNotNil() {

        // Arrange

        sutWebSocketClient.onConnect = { }

        // Assert

        XCTAssertNotNil(sutWebSocketClient.onConnect)
    }

    // MARK: - onDisconnect

    func testOnDisconnect() {

        // Arrange

        let expectation = expectation(description: ".onDisconnect should be called")

        var isOnDisconnectCalled = false

        sutWebSocketClient.onDisconnect = { _ in
            isOnDisconnectCalled = true
            expectation.fulfill()
        }

        // Act

        sutWebSocketClient.disconnect()
        webSocketProtocolMock.onDisconnect?(nil)
        waitForExpectations(timeout: 5, handler: nil)

        // Assert

        XCTAssertTrue(isOnDisconnectCalled)
        XCTAssertTrue(webSocketProtocolMock.disconnectForceTimeoutTimeIntervalCloseCodeUInt16VoidCalled)
    }

    func testDisconnectNotNil() {

        // Arrange

        sutWebSocketClient.onDisconnect = { _ in }

        // Assert

        XCTAssertNotNil(sutWebSocketClient.onDisconnect)
    }

    // MARK: - onText

    func testOnChannelUpdate() {
        // Arrange

        let expectation = expectation(description: ".onChannelUpdate should be called")

        var isOnChannelUpdateCalled = false

        sutWebSocketClient.onChannelUpdate = { _ in
            isOnChannelUpdateCalled = true
            expectation.fulfill()
        }

        // Act

        webSocketProtocolMock.onText?("")
        waitForExpectations(timeout: 5, handler: nil)

        // Assert

        XCTAssertTrue(isOnChannelUpdateCalled)
    }

    func testOnChannelUpdateNotNil() {
        // Arrange

        sutWebSocketClient.onChannelUpdate = { _ in }

        // Assert

        XCTAssertNotNil(sutWebSocketClient.onChannelUpdate)
    }
}
