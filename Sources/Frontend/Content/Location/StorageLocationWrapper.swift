import Foundation

/// Model for uploading file with location
struct StorageLocationWrapper: Codable, DataInitializable {
    private static let decoder = ChatJSONDecoder()

    let longitude: Double
    let latitude: Double

    init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }

    init?(data: Data) {
        guard let object = try? Self.decoder.decode(StorageLocationWrapper.self, from: data) else {
            return nil
        }

        self.longitude = object.longitude
        self.latitude = object.latitude
    }
}
