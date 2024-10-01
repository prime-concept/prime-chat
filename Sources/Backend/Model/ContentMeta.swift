import Foundation

public struct ContentMeta: Codable {
    let contactName: String?
    let contactPhone: String?
    
    let locationLatitude: Double?
    let locationLongitude: Double?
    
    let imageWidth: Int?
    let imageHeight: Int?
    let imageBlurPreview: String?
    
    let videoDuration: Double?
    let videoWidth: Int?
    let videoHeight: Int?
    let videoBlurPreview: String?
    
    let documentSize: Double?
    let documentName: String?
    
    init(
        contactName: String? = nil,
        contactPhone: String? = nil,
        locationLatitude: Double? = nil,
        locationLongitude: Double? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageBlurPreview: String? = nil,
        videoDuration: Double? = nil,
        videoWidth: Int? = nil,
        videoHeight: Int? = nil,
        videoBlurPreview: String? = nil,
        documentSize: Double? = nil,
        documentName: String? = nil
    ) {
        self.contactName = contactName
        self.contactPhone = contactPhone
        self.locationLatitude = locationLatitude
        self.locationLongitude = locationLongitude
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageBlurPreview = imageBlurPreview
        self.videoDuration = videoDuration
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
        self.videoBlurPreview = videoBlurPreview
        self.documentSize = documentSize
        self.documentName = documentName
    }
    
    enum CodingKeys: String, CodingKey {
        case contactName = "contact_name"
        case contactPhone = "contact_phone"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case imageWidth = "image_width"
        case imageHeight = "image_height"
        case imageBlurPreview = "image_blurred_preview"
        case videoDuration = "video_duration"
        case videoWidth = "video_width"
        case videoHeight = "video_height"
        case videoBlurPreview = "video_blurred_preview"
        case documentSize = "document_size"
        case documentName = "document_name"
    }
}
