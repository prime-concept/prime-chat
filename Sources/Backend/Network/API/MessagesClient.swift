import Foundation

enum MessagesLoadDirection: String {
    case older = "OLDER"
    case newer = "NEWER"
}

protocol MessagesClientProtocol: AnyObject, AutoMockable {
    func create(
        message: Message,
        time: Int,
        completion: @escaping APIResultCallback<CreateMessageResponse>
    ) throws -> URLSessionTask?

    // swiftlint:disable:next function_parameter_count
    func retrieve(
        channelID: String?,
        guid: String?,
        limit: Int?,
        time: Int,
        fromTime: Int?,
        toTime: Int?,
        direction: MessagesLoadDirection,
        completion: @escaping APIResultCallback<MessagesResponse>
    ) throws -> URLSessionTask?

    func update(
        guids: [String],
        status: MessageStatus,
        completion: @escaping APIResultCallback<MessagesUpdateResponse>
    ) throws -> URLSessionTask?
}

final class MessagesClient: APIClient, MessagesClientProtocol {
    private static let basePath = "/messages"

    private static let decoder = ChatJSONDecoder()
    private static let encoder = JSONEncoder()

    func create(
        message: Message,
        time: Int,
        completion: @escaping APIResultCallback<CreateMessageResponse>
    ) throws -> URLSessionTask? {
        let parameters = ["t": "\(time)"]

        return try self.create(
            path: Self.basePath,
            queryParameters: parameters,
            data: message,
            decoder: Self.decoder,
            encoder: Self.encoder,
            completion: completion
        )
    }

    private var pendingRetrieveRequests: [String: Bool] = [:]

    // swiftlint:disable:next function_parameter_count
    func retrieve(
        channelID: String?,
        guid: String?,
        limit: Int?,
        time: Int,
        fromTime: Int?,
        toTime: Int?,
        direction: MessagesLoadDirection,
        completion: @escaping APIResultCallback<MessagesResponse>
    ) throws -> URLSessionTask? {
        var parameters = ["t": "\(time)"]

        if let channelID = channelID {
            parameters["channelId"] = channelID
        }

        if let guid = guid {
            parameters["guid"] = guid
        }

        if let limit = limit {
            parameters["limit"] = "\(limit)"
        }

        if let fromTime = fromTime {
            parameters["from"] = "\(fromTime)"
        }

        if let toTime = toTime {
            parameters["to"] = "\(toTime)"
        }

        parameters["direction"] = direction.rawValue

        return try self.retrieve(
            path: Self.basePath,
            parameters: parameters,
            decoder: Self.decoder,
            completion: { (result: Result<APIClient.HTTPResult<MessagesResponse>, APIClient.NetworkError>) in
                completion(result)
            }
        )
    }

    func update(
        guids: [String],
        status: MessageStatus,
        completion: @escaping APIResultCallback<MessagesUpdateResponse>
    ) throws -> URLSessionTask? {
        let parameters = ["guid": guids.joined(separator: ","), "status": status.rawValue]

        return try self.update(
            path: Self.basePath,
            queryParameters: parameters,
            data: Data?.none,
            decoder: Self.decoder,
            encoder: Self.encoder,
            completion: completion
        )
    }
}

public class MiscClient: APIClient {
    public struct UnreadInfo: Codable {
        public let channelId: String
        public let unreadCount: Int
    }

    private static let decoder = ChatJSONDecoder()

    public func retrieveUnreadCountsPerChats(completion: @escaping ([UnreadInfo]?) -> Void) throws {
        _ = try self.retrieve(
            path: "unreadCount",
            decoder: Self.decoder,
            completion: { (result: Result<APIClient.HTTPResult<[UnreadInfo]>, APIClient.NetworkError>) in
                if case .success(let count) = result {
                    completion(count.data)
                    return
                }
                completion(nil)
            }
        )
    }

    public func retrieveTotalUnreadCount(completion: @escaping (Int?) -> Void) throws {
        _ = try self.retrieve(
            path: "totalUnreadCount",
            decoder: Self.decoder,
            completion: { (result: Result<APIClient.HTTPResult<Int>, APIClient.NetworkError>) in
                if case .success(let count) = result {
                    completion(count.data)
                    return
                }
                completion(nil)
            }
        )
    }
}
