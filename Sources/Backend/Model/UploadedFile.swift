import Foundation

struct UploadedFile: Decodable, Equatable {
    let name: String
    let path: String
    let privacy: Privacy
    let uuid: String
    let checksum: String?
    let type: String
    let error: String?

    // MARK: - Enums

    enum Privacy: String, Decodable {
        case `public` = "PUBLIC"
        case `private` = "PRIVATE"
    }
}
