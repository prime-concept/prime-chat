import Foundation

final class ChatJSONDecoder: JSONDecoder {
    override init() {
        super.init()
        self.dateDecodingStrategy = .formatted(Self.makeHumanReadableFormatter())
    }

    private static func makeHumanReadableFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}
