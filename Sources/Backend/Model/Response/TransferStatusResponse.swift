import Foundation

struct TransferStatusResponse: Decodable {
    let percentTransfered: Float
    let bytesTransfered: Int
    let name: String
    let uuid: String
}
