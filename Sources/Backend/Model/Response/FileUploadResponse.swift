import Foundation

enum FilesUploadResponse: Decodable {
    case result([UploadedFile])
    case error(Error)

    struct Error {
        let description: String
        let code: Int
    }

    enum CodingKeys: String, CodingKey {
        case result
        case description
        case code
    }

    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)

        let result = try? container?.decode([UploadedFile].self, forKey: .result)
        let description = try? container?.decode(String.self, forKey: .description)
        let code = try? container?.decode(Int.self, forKey: .code)

        if let result = result {
            self = .result(result)
        } else if let description = description, let code = code {
            self = .error(.init(description: description, code: code))
        } else {
            throw ResponseError.decodingFailed
        }
    }

    enum ResponseError: Swift.Error {
        case decodingFailed
    }
}
