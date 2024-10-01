import Foundation

class URLProtocolApiClientRetrieveSuccessMock: URLProtocol {

    /// what types of the request to handle
    override class func canInit(with request: URLRequest) -> Bool {
        request.url!.absoluteString.contains("testRetrieve")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    /// start loading
    override func startLoading() {

        let statusCode = 200
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
        "status": "SUCCESS",
        "id": 1
    }
    """
}
