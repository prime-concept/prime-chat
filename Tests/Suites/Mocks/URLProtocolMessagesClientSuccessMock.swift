//
//  URLProtocolMessagesClientSuccessMock.swift
//  ChatSDK
//
//  Created by Hayk Kolozyan on 17.05.24.
//

import Foundation

class URLProtocolMessagesClientSuccessMock: URLProtocol {

    /// what types of the request to handle
    override class func canInit(with request: URLRequest) -> Bool {
        request.url!.absoluteString.hasPrefix("example.com/messages")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    /// start loading
    override func startLoading() {

        let statusCode: Int
        let dataLoaded: Data
        
        statusCode = 200
        if request.url!.absoluteString.contains("direction=OLDER") {
            dataLoaded = Self.jsonStringOlder.data(using: .utf8)!
        } else {
            dataLoaded = Self.jsonStringNewer.data(using: .utf8)!
        }

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: dataLoaded)

        client?.urlProtocolDidFinishLoading(self)
    }

    /// this method is required but doesn't need to do anything
    override func stopLoading() { }

    // MARK: - json

    private static let jsonStringOlder =
    """
    {
        "status": "SUCCESS",
        "items": [
            {
                "guid": "1",
                "timestamp": 1627477300,
                "channelId": "general",
                "status": "NEW",
                "source": "CHAT"
            },
            {
                "guid": "2",
                "timestamp": 1627477301,
                "channelId": "general",
                "status": "NEW",
                "source": "CHAT"
            }
        ]
    }
    """

    private static let jsonStringNewer =
    """
    {
        "status": "SUCCESS",
        "items": [
            {
                "guid": "1",
                "timestamp": 1627477311,
                "channelId": "general",
                "status": "NEW",
                "source": "CHAT"
            },
            {
                "guid": "2",
                "timestamp": 1627477301,
                "channelId": "general",
                "status": "NEW",
                "source": "CHAT"
            }
        ]
    }
    """
}
