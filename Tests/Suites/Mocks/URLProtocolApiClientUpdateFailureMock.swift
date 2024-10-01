import Foundation

class URLProtocolApiClientUpdateFailureMock: URLProtocol {

    /// what types of the request to handle
    override class func canInit(with request: URLRequest) -> Bool {
        request.url!.absoluteString.contains("testUpdateFailure")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    /// start loading
    override func startLoading() {
        let error = NSError(
            domain: "RestrictedContentException",
            code: 400,
            userInfo: ["status": "ERROR"]
        )

        client?.urlProtocol(self, didFailWithError: error)
        client?.urlProtocolDidFinishLoading(self)
    }

    /// this method is required but doesn't need to do anything
    override func stopLoading() { }
}
