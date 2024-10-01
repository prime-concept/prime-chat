import GRDB
import Foundation

// There is no implementation of DatabaseValueConvertible
// cause ambiguous fetch methods call will be ocurred in CacheService
protocol JSONDatabaseValueConvertible: Codable { }

extension JSONDatabaseValueConvertible {
    var databaseValue: DatabaseValue {
        let encoder = JSONEncoder()

        let json = (try? encoder.encode(self)).flatMap { data in
            String(data: data, encoding: .utf8)
        }

        return json.flatMap { DatabaseValue(value: $0) } ?? .null
    }

    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
        if dbValue.databaseValue.isNull {
            return nil
        }

        switch dbValue.databaseValue.storage {
        case .string(let json):
            guard let data = json.data(using: .utf8) else {
                return nil
            }

            let decoder = ChatJSONDecoder()
            return try? decoder.decode(Self.self, from: data)
        default:
            return nil
        }
    }
}
