//
//  URLProtocolMessagesClientFailedMock.swift
//  ChatSDK
//
//  Created by Hayk Kolozyan on 17.05.24.
//

import Foundation

class URLProtocolMessagesClientFailedMock: URLProtocol {

    /// what types of the request to handle
    override class func canInit(with request: URLRequest) -> Bool {
        request.url!.absoluteString.hasPrefix("example.com/messages")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    /// start loading
    override func startLoading() {

        let statusCode: Int
        let dataLoaded: Data

        statusCode = 400
        dataLoaded = Self.jsonErrorString.data(using: .utf8)!

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

    private static let jsonErrorString =
    """
    {
        "body": null,
        "error": {
            "code": 400,
            "exception": "RestrictedContentException",
            "message": "error message"
        },
        "status": "ERROR"
    }
    """
}
