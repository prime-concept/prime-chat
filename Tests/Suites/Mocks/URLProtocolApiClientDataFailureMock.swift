import Foundation

class URLProtocolApiClientDataFailureMock: URLProtocol {

    /// what types of the request to handle
    override class func canInit(with request: URLRequest) -> Bool {
        request.url!.absoluteString.contains("testDataFailure")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    /// start loading
    override func startLoading() {

        let statusCode = 400
        let dataLoaded = Self.jsonString.data(using: .utf8)!

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

    private static let jsonString =
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
