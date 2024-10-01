import UIKit

/// Font descriptor
public struct FontDescriptor {
    public let font: UIFont
    public let lineHeight: CGFloat?
    public let baselineOffset: CGFloat

    public init(font: UIFont, lineHeight: CGFloat? = nil, baselineOffset: CGFloat = 0.0) {
        self.font = font
        self.lineHeight = lineHeight
        self.baselineOffset = baselineOffset
    }
}

public extension UIFont {
    var pch_fontDescriptor: FontDescriptor { FontDescriptor(font: self) }
}

/// Wrapper for all element's style providers
public protocol FontProvider {
    var timeSeparator: FontDescriptor { get }
    var locationPickTitle: FontDescriptor { get }
    var locationPickSubtitle: FontDescriptor { get }
    var badge: FontDescriptor { get }
    var pickerVideoDuration: FontDescriptor { get }
    var pickerAlbumTitle: FontDescriptor { get }
    var pickerAlbumCount: FontDescriptor { get }
    var pickerActionsButton: FontDescriptor { get }
    var previewVideoDuration: FontDescriptor { get }
    var voiceMessageRecordingTime: FontDescriptor { get }
    var voiceMessageRecordingTitle: FontDescriptor { get }
    var replyName: FontDescriptor { get }
    var replyText: FontDescriptor { get }
    var senderPlaceholder: FontDescriptor { get }
    var senderBadge: FontDescriptor { get }
    var documentName: FontDescriptor { get }
    var documentSize: FontDescriptor { get }
    var videoInfoTime: FontDescriptor { get }
    var contactTitle: FontDescriptor { get }
    var contactPhone: FontDescriptor { get }
    var voiceMessageDuration: FontDescriptor { get }
    var messageText: FontDescriptor { get }
    var messageInfoTime: FontDescriptor { get }
    var messageReplyName: FontDescriptor { get }
    var messageReplyText: FontDescriptor { get }
    var navigationTitle: FontDescriptor { get }
    var navigationButton: FontDescriptor { get }
}

extension FontProvider {
    public var timeSeparator: FontDescriptor { UIFont.systemFont(ofSize: 13).pch_fontDescriptor }
    public var locationPickTitle: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var locationPickSubtitle: FontDescriptor { UIFont.systemFont(ofSize: 12).pch_fontDescriptor }
    public var badge: FontDescriptor { UIFont.systemFont(ofSize: 17).pch_fontDescriptor }
    public var pickerVideoDuration: FontDescriptor { UIFont.systemFont(ofSize: 12).pch_fontDescriptor }
    public var pickerAlbumTitle: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var pickerAlbumCount: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var pickerActionsButton: FontDescriptor { UIFont.systemFont(ofSize: 17).pch_fontDescriptor }
    public var previewVideoDuration: FontDescriptor { UIFont.systemFont(ofSize: 12).pch_fontDescriptor }
    public var voiceMessageRecordingTime: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var voiceMessageRecordingTitle: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var replyName: FontDescriptor { UIFont.systemFont(ofSize: 12).pch_fontDescriptor }
    public var replyText: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var senderPlaceholder: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var senderBadge: FontDescriptor { UIFont.systemFont(ofSize: 12).pch_fontDescriptor }
    public var documentName: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var documentSize: FontDescriptor { UIFont.systemFont(ofSize: 12).pch_fontDescriptor }
    public var videoInfoTime: FontDescriptor { UIFont.systemFont(ofSize: 11).pch_fontDescriptor }
    public var contactTitle: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var contactPhone: FontDescriptor { UIFont.systemFont(ofSize: 12).pch_fontDescriptor }
    public var voiceMessageDuration: FontDescriptor { UIFont.systemFont(ofSize: 11).pch_fontDescriptor }
    public var messageText: FontDescriptor { UIFont.systemFont(ofSize: 16).pch_fontDescriptor }
    public var messageInfoTime: FontDescriptor { UIFont.systemFont(ofSize: 11).pch_fontDescriptor }
    public var messageReplyName: FontDescriptor { UIFont.systemFont(ofSize: 12, weight: .semibold).pch_fontDescriptor }
    public var messageReplyText: FontDescriptor { UIFont.systemFont(ofSize: 13).pch_fontDescriptor }
    public var navigationTitle: FontDescriptor { UIFont.systemFont(ofSize: 17, weight: .semibold).pch_fontDescriptor }
    public var navigationButton: FontDescriptor { UIFont.systemFont(ofSize: 17).pch_fontDescriptor }
}
