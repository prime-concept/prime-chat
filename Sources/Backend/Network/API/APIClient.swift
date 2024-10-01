import Foundation

typealias APIResultCallback<T> = (Result<APIClient.HTTPResult<T>, APIClient.NetworkError>) -> Void
typealias ProgressCallback = (Float) -> Void
typealias DownloadCallback = (Result<URL, APIClient.NetworkError>) -> Void
typealias RawResultCallback = (Result<(data: Data, response: URLResponse), APIClient.NetworkError>) -> Void

enum APIClientMimeType {
    case audio
    case video
    case vcard
    case plain
    case imageJPG
    case imagePNG
    case unknown
    case other(mimeType: String)

    var stringValue: String {
        switch self {
        case .audio:
            return "audio/mp4"
        case .video:
            return "video/mp4"
        case .vcard:
            return "text/x-vcard"
        case .plain:
            return "text/plain"
        case .imageJPG:
            return "image/jpeg"
        case .imagePNG:
            return "image/png"
        case .unknown:
            return "application/octet-stream"
        case .other(let mimeType):
            return mimeType
        }
    }
}

protocol APIClientProtocol {
    var cache: Self { get }

    func retrieve<T: Decodable>(
        path: String,
        parameters: [String: String],
        headers: [String: String],
        decoder: JSONDecoder,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionTask

    // swiftlint:disable:next function_parameter_count
    func create<U: Encodable, T: Decodable>(
        path: String,
        queryParameters: [String: String],
        data: U?,
        headers: [String: String],
        decoder: JSONDecoder,
        encoder: JSONEncoder,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionTask

    // swiftlint:disable:next function_parameter_count
    func update<U: Encodable, T: Decodable>(
        path: String,
        queryParameters: [String: String],
        data: U?,
        headers: [String: String],
        decoder: JSONDecoder,
        encoder: JSONEncoder,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionTask

    // swiftlint:disable:next function_parameter_count
    func multipart<T: Decodable>(
        path: String,
        filename: String,
        mimeType: APIClientMimeType,
        data: Data,
        headers: [String: String],
        timeout: TimeInterval?,
        decoder: JSONDecoder,
        progress: ProgressCallback?,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionTask

    func data(path: String, completion: @escaping RawResultCallback) throws -> URLSessionTask
    func download(
        path: String,
        progress: ProgressCallback?,
        completion: @escaping DownloadCallback
    ) throws -> URLSessionDownloadTask
}

// swiftlint:disable:next type_body_length
public class APIClient {
    fileprivate final class FakeDataTask: URLSessionDataTask {
        override var state: URLSessionTask.State {
            .completed
        }

        override var progress: Progress {
            let progress = Progress(totalUnitCount: 1)
            progress.completedUnitCount = 1
            return progress
        }

        override func resume() { }
    }
    
    enum DataSource {
        case server
        case cache
    }

    private(set) var dataSource: DataSource = .server

    func getCache() -> Self {
        return self
    }

    var cache: Self {
        let endpoint = Self.init(
            baseURL: self.baseURL,
            authState: self.authState,
            urlSessionConfiguration: APIClient.urlSessionConfiguration
        )
        endpoint.dataSource = .cache
        return endpoint
    }

    public static let urlSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30

        return configuration
    }()

    private static let decodingQueue = DispatchQueue(label: "APIClient.decoding", qos: .userInitiated)
    private static let encodingQueue = DispatchQueue(label: "APIClient.encoding", qos: .userInitiated)

    private var taskTracker: URLSessionTaskStatusTracker

    private let urlSession: URLSession
    private let baseURL: URL

    let authState: AuthStateProtocol

    public required init(
        baseURL: URL,
        authState: AuthStateProtocol,
        urlSessionConfiguration: URLSessionConfiguration = APIClient.urlSessionConfiguration
    ) {
        self.baseURL = baseURL
        self.taskTracker = URLSessionTaskStatusTracker()
        self.urlSession = URLSession(
            configuration: urlSessionConfiguration,
            delegate: self.taskTracker,
            delegateQueue: OperationQueue.main
        )
        self.authState = authState
    }

    deinit {
        self.taskTracker.purge()
        self.urlSession.invalidateAndCancel()
    }

    // MARK: - Enums

    struct HTTPResult<T> {
        let httpStatusCode: Int
        let data: T?
    }

    enum HTTPMethod: String {
        case get
        case post
        case put
        case delete
    }

    enum DataError: Swift.Error {
        case invalidURL
        case invalidDataEncoding
    }

    enum NetworkError: Swift.Error, Equatable {
        case urlSession(Swift.Error)
        case invalidResponse
        case noCachedData
        case unknown

        static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
            switch (lhs, rhs) {
            case (.urlSession(let lhsError), .urlSession(let rhsError)):
                return (lhsError as NSError).domain == (rhsError as NSError).domain &&
                (lhsError as NSError).code == (rhsError as NSError).code
            case (.invalidResponse, .invalidResponse),
                (.noCachedData, .noCachedData),
                (.unknown, .unknown):
                return true
            default:
                return false
            }
        }
    }
}

// MARK: - APIClientProtocol

extension APIClient: APIClientProtocol {
    func retrieve<T: Decodable>(
        path: String,
        parameters: [String: String] = [:],
        headers: [String: String] = [:],
        decoder: JSONDecoder,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionTask {
        return try self.request(
            url: Self.makeCompleteURL(from: self.baseURL, path: path),
            headers: headers,
            queryParameters: parameters,
            contentType: nil,
            body: nil,
            method: .get,
            decoder: decoder,
            completion: completion
        )
    }

    func create<U: Encodable, T: Decodable>(
        path: String,
        queryParameters: [String: String] = [:],
        data: U?,
        headers: [String: String] = [:],
        decoder: JSONDecoder,
        encoder: JSONEncoder,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionTask {
        var encodedData = Data()

        try Self.encodingQueue.sync {
            do {
                encodedData = try encoder.encode(data)
            } catch {
                let userInfo: [String: Any] = [
                    "sender": "\(type(of: self)) create<U: Encodable, T: Decodable>",
                    "details": "\(#function) DataError.invalidDataEncoding: \(String(describing: data))"
                ]
                NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
                
                throw DataError.invalidDataEncoding
            }
        }

        return try self.request(
            url: Self.makeCompleteURL(from: self.baseURL, path: path),
            headers: headers,
            queryParameters: queryParameters,
            contentType: "application/json",
            body: encodedData,
            method: .post,
            decoder: decoder,
            completion: completion
        )
    }

    func update<U: Encodable, T: Decodable>(
        path: String,
        queryParameters: [String: String] = [:],
        data: U?,
        headers: [String: String] = [:],
        decoder: JSONDecoder,
        encoder: JSONEncoder,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionTask {
        var encodedData = Data()

        try Self.encodingQueue.sync {
            do {
                encodedData = try encoder.encode(data)
            } catch {
                let userInfo: [String: Any] = [
                    "sender": "\(type(of: self)) update<U: Encodable, T: Decodable>",
                    "details": "\(#function) DataError.invalidDataEncoding: \(String(describing: data))"
                ]
                NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

                throw DataError.invalidDataEncoding
            }
        }

        return try self.request(
            url: Self.makeCompleteURL(from: self.baseURL, path: path),
            headers: headers,
            queryParameters: queryParameters,
            contentType: "application/json",
            body: encodedData,
            method: .put,
            decoder: decoder,
            completion: completion
        )
    }

    // swiftlint:disable:next function_parameter_count
    func multipart<T: Decodable>(
        path: String,
        filename: String,
        mimeType: APIClientMimeType,
        data: Data,
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        decoder: JSONDecoder,
        progress: ProgressCallback? = nil,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionTask {
        let boundary = UUID().uuidString
        let contentType = "multipart/form-data; boundary=\(boundary)"

        var body = Data()
        Self.encodingQueue.sync {
            body = Self.makeMultipartDataBody(boundary: boundary, filename: filename, data: data, mimeType: mimeType)
        }

        let task = try self.request(
            url: Self.makeCompleteURL(from: self.baseURL, path: path),
            headers: headers,
            queryParameters: [:],
            contentType: contentType,
            timeout: timeout,
            body: body,
            method: .post,
            decoder: decoder,
            shouldStartImmediately: false,
            completion: completion
        )
        if let progress = progress {
            self.taskTracker.append(taskID: task.taskIdentifier, callback: progress)
        }
        return task
    }

    func download(
        path: String,
        progress: ProgressCallback?,
        completion: @escaping DownloadCallback
    ) throws -> URLSessionDownloadTask {
        var request = URLRequest(url: self.baseURL.appendingPathComponent(path))

        self.authState.bearerToken.flatMap {
            let token = "Bearer \($0)"
            request.addValue(token, forHTTPHeaderField: "Authorization")
            request.addValue(token, forHTTPHeaderField: "X-Access-Token")
            request.addValue(token, forHTTPHeaderField: "access_token")
        }

        log(sender: self, "request download\n\turl = \(request.url?.absoluteString ?? "<invalid>")")
        let task = self.makeDownloadTask(urlRequest: request)

        progress.flatMap { self.taskTracker.append(taskID: task.taskIdentifier, callback: $0) }

        self.taskTracker.append(taskID: task.taskIdentifier, callback: completion)
        return task
    }

    func data(path: String, completion: @escaping RawResultCallback) throws -> URLSessionTask {
        var request = URLRequest(url: self.baseURL.appendingPathComponent(path))

        self.authState.bearerToken.flatMap {
            let token = "Bearer \($0)"
            request.addValue(token, forHTTPHeaderField: "Authorization")
            request.addValue(token, forHTTPHeaderField: "X-Access-Token")
            request.addValue(token, forHTTPHeaderField: "access_token")
        }

        log(sender: self, "request raw data\n\turl = \(request.url?.absoluteString ?? "<invalid>")")
        
        let task = self.makeDataTask(
            urlRequest: request,
            queryParameters: [:],
            completion: completion
        )
        return task
    }
}

// MARK: - Private

private extension APIClient {

    static func makeMultipartDataBody(
        boundary: String,
        filename: String,
        data: Data,
        mimeType: APIClientMimeType
    ) -> Data {
        let body = NSMutableData()

        let boundaryPrefix = "--\(boundary)\r\n"
        body.append(string: boundaryPrefix)
        body.append(string: "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.append(string: "Content-Type: \(mimeType.stringValue)\r\n\r\n")
        body.append(data)
        body.append(string: "\r\n")
        body.append(string: "--\(boundary)--")

        return body as Data
    }

    static func makeMultipartTextBody(
        boundary: String,
        headers: [String: String]
    ) -> Data {
        let body = NSMutableData()

        let boundaryPrefix = "--\(boundary)\r\n"

        for (key, value) in headers {
            body.append(string: boundaryPrefix)
            body.append(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append(string: "\(value)\r\n")
        }

        body.append(string: "\r\n")
        body.append(string: "--\(boundary)--")

        return body as Data
    }

    func makeAuthHeaders() -> [String: String] {
        var items: [String: String] = [:]

        if let clientAppID = self.authState.clientAppID {
            items["X-Client-Id"] = clientAppID
        }

        if let deviceID = self.authState.deviceID {
            items["X-Device-Id"] = deviceID
        }

        if let wsID = self.authState.wsUniqueID {
            items["X-Socket-Id"] = wsID
        }

        if let accessToken = self.authState.accessToken {
            items["X-Access-Token"] = accessToken
            items["access_token"] = accessToken
        }

        if let bearer = self.authState.bearerToken {
            items["Authorization"] = bearer
        }

        return items
    }

    static func makeCompleteURL(from url: URL, path: String) -> URL {
        return url.appendingPathComponent(path)
    }

    // swiftlint:disable:next function_parameter_count
    func request<T: Decodable>(
        url: URL,
        headers: [String: String],
        queryParameters: [String: String],
        contentType: String?,
        timeout: TimeInterval? = nil,
        body: Data?,
        method: HTTPMethod,
        decoder: JSONDecoder,
        shouldStartImmediately: Bool = true,
        completion: @escaping APIResultCallback<T>
    ) throws -> URLSessionDataTask {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) request<T: Decodable> 1",
                "details": "\(#function) DataError.invalidURL, bad url: \(url.absoluteString)"
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            throw DataError.invalidURL
        }

        urlComponents.queryItems = queryParameters.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        guard let componentsURL = urlComponents.url else {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) request<T: Decodable> 2",
                "details": "\(#function) DataError.invalidURL, bad components: \(urlComponents)"
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            throw DataError.invalidURL
        }

        var request = URLRequest(url: componentsURL)
        for header in headers.merging(self.makeAuthHeaders(), uniquingKeysWith: { $1 }) {
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }

        request.httpBody = body
        request.httpMethod = method.rawValue

        if let timeout = timeout {
            request.timeoutInterval = timeout
        }

        let task = self.request(
            urlRequest: request,
            queryParameters: queryParameters,
            decoder: decoder,
            completion: completion
        )

        let debugString = "http request:\n" + request.cURL
        log(sender: self, debugString)

        if shouldStartImmediately {
            task.resume()
        }

        return task
    }

    // swiftlint:disable all
    func request<T: Decodable>(
        urlRequest: URLRequest,
        queryParameters: [String: String],
        decoder: JSONDecoder,
        completion: @escaping APIResultCallback<T>
    ) -> URLSessionDataTask {
        return self.makeDataTask(urlRequest: urlRequest, queryParameters: queryParameters) { result in
            let curl = urlRequest.cURL
            let sender = "\(type(of: self)) request<T: Decodable> 3, decode(data: Data, statusCode: Int)"

            func decode(data: Data, statusCode: Int) -> HTTPResult<T> {
                // Replace empty response (e.g. when message posted) by valid empty JSON "{}"
                let jsonData = data.isEmpty ? Data([UInt8]([123, 125])) : data
                let responseString = String(data: data, encoding: .utf8) ?? ""
                log(sender: self, "response for: \(curl)\n\n\(responseString)")

                do {
                    let decodedResult = try decoder.decode(T.self, from: jsonData)
                    let httpResult = HTTPResult(httpStatusCode: statusCode, data: decodedResult)
                    return httpResult
                } catch {
                    log(sender: self, "invalid decoding \(error)")
                    log(sender: self, "dump data ->\n \(responseString)")

                    let userInfo: [String: Any] = [
                        "curl": curl,
                        "response": responseString,
                        "error": error,
                        "sender": sender
                    ]

                    NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

                    let httpResult = HTTPResult<T>(httpStatusCode: statusCode, data: nil)
                    return httpResult
                }
            }

            switch result {
            case .success(let result):
                let (data, _) = result

                Self.decodingQueue.async {
                    let httpResult = decode(data: data, statusCode: 200)
                    DispatchQueue.main.async {
                        completion(.success(httpResult))
                    }
                }
            case .failure(let error):
                let userInfo: [String: Any] = [
                    "curl": curl,
                    "error": error,
                    "sender": sender
                ]
                NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
                completion(.failure(error))
            }
        }
    }
    // swiftlint:enable all

    func makeDataTask(
        urlRequest: URLRequest,
        queryParameters: [String: String],
        completion: @escaping RawResultCallback
    ) -> URLSessionDataTask {
        if self.dataSource == .cache {
            if
                let url = urlRequest.url,
                let data = ResponseCacheService.shared.data(for: url, parameters: queryParameters)
            {
                DispatchQueue.main.async {
                    completion(.success((data: data, response: URLResponse())))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(.noCachedData))
                }
            }

            return FakeDataTask()
        }

        return self.urlSession.dataTask(with: urlRequest) { data, response, error in
            if
                let data = data,
                let response = response as? HTTPURLResponse,
                (200..<300) ~= response.statusCode
            {
                /* Currently there no need to cache responses, bc chat already stores its Messages in DB
                 ResponseCacheService.shared.write(
                 data: data,
                 for: urlRequest.url,
                 parameters: queryParameters
                 )
                 */
                DispatchQueue.main.async {
                    completion(.success((data: data, response: response)))
                }
                return
            }

            /*
             if let url = urlRequest.url, !NetworkMonitor.shared.isConnected {
             let data = ResponseCacheService.shared.data(for: url, parameters: queryParameters)
             if let data = data {
             let response = response ?? URLResponse()
             DispatchQueue.main.async {
             completion(.success((data: data, response: response)))
             }
             return
             }
             }
             */

            let curl = urlRequest.cURL
            let sureError = error ?? NSError(
                domain: "CHAT",
                code: (response as? HTTPURLResponse)?.statusCode ?? -1
            )

            let userInfo: [String: Any] = [
                "curl": curl,
                "sender": "\(type(of: self)) makeDataTask",
                "error": sureError
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.urlSession(error)))
                } else {
                    completion(.failure(.unknown))
                }
            }
        }
    }

    func makeDownloadTask(
        urlRequest: URLRequest
    ) -> URLSessionDownloadTask {
        return self.urlSession.downloadTask(with: urlRequest)
    }
}

// MARK: - NSMutableData+appendString

extension NSMutableData {
    func append(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        self.append(data ?? Data())
    }
}

// MARK: - URLSessionTaskStatusTracker+URLSessionTaskDelegate

private class URLSessionTaskStatusTracker: NSObject, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    private var taskIDToProgress: [Int: ProgressCallback] = [:]
    private var taskIDToURL: [Int: DownloadCallback] = [:]

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        self.taskIDToProgress[downloadTask.taskIdentifier]?(progress)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let requestURL = downloadTask.originalRequest?.url else {
            return
        }
        self.taskIDToURL[downloadTask.taskIdentifier]?(.success(location))
        self.taskIDToURL[downloadTask.taskIdentifier] = nil
        log(sender: self, "finish downloading\n\turl = \(requestURL.absoluteString) to \n\t\(location)")
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        self.taskIDToProgress[task.taskIdentifier]?(progress)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.taskIDToURL[task.taskIdentifier]?(.failure(.urlSession(error)))
        }
        self.taskIDToProgress[task.taskIdentifier] = nil
        self.taskIDToURL[task.taskIdentifier] = nil
        let errorDescription = error?.localizedDescription ?? ""
        log(
            sender: self,
            "ERROR: \(#function) \(task.currentRequest?.url?.absoluteString ?? "") ERROR: \(errorDescription)"
        )
    }

    // MARK: - Public

    func append(taskID: Int, callback: @escaping ProgressCallback) {
        self.taskIDToProgress[taskID] = callback
    }

    func append(taskID: Int, callback: @escaping DownloadCallback) {
        self.taskIDToURL[taskID] = callback
    }

    func purge() {
        self.taskIDToURL.removeAll()
        self.taskIDToProgress.removeAll()
    }
}
