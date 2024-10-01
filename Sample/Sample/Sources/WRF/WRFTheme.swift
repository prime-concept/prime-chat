import UIKit
import ChatSDK

class WRFPalette: ThemePalette {
    static let grayColor = UIColor(hex: 0x949494)
    static let lightGrayColor = UIColor(hex: 0xcccbcb)

    var bubbleOutcomeBackground: UIColor { .black }
    var bubbleOutcomeText: UIColor { .white }
    var bubbleOutcomeInfoTime: UIColor { Self.grayColor }

    var bubbleIncomeBorder: UIColor { Self.lightGrayColor }
    var bubbleOutcomeBorder: UIColor { .clear }
    
    var bubbleIncomeBackground: UIColor { .white }
    var bubbleIncomeText: UIColor { .black }
    var bubbleIncomeInfoTime: UIColor { Self.grayColor }

    var bubbleBorder: UIColor { UIColor(hex: 0xe5e5e5) }
    var bubbleInfoPadBackground: UIColor { UIColor.black.withAlphaComponent(0.3) }
    var bubbleInfoPadText: UIColor { .white }

    var timeSeparatorText: UIColor { .white }
    var timeSeparatorBackground: UIColor { UIColor.black.withAlphaComponent(0.2) }

    var voiceMessageRecordingCircleTint: UIColor { .black }
    var voiceMessageRecordingCircleBackground: UIColor { Self.lightGrayColor.withAlphaComponent(0.5) }
    var voiceMessageRecordingTime: UIColor { .black }
    var voiceMessageRecordingIndicator: UIColor { UIColor(hex: 0xff3f3f) }
    var voiceMessageRecordingDismissTitle: UIColor { Self.grayColor }
    var voiceMessageRecordingDismissIndicator: UIColor { Self.lightGrayColor }

    var senderButton: UIColor { .black }
    var senderBorderShadow: UIColor { UIColor(hex: 0xd1d1d6) }
    var senderBackground: UIColor { .white }
    var senderPlaceholderColor: UIColor { UIColor(hex: 0x8e8e93) }
    var senderTextColor: UIColor { .black }

    var contactIconIncomeBackground: UIColor { Self.lightGrayColor }
    var contactIconOutcomeBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var contactIcon: UIColor { UIColor.white }
    var contactIncomeTitle: UIColor { .black }
    var contactOutcomeTitle: UIColor { .white }
    var contactIncomePhone: UIColor { Self.grayColor }
    var contactOutcomePhone: UIColor { Self.grayColor }

    var locationPickBackground: UIColor { .white }
    var locationPickTitle: UIColor { .black }
    var locationPickSubtitle: UIColor { Self.grayColor }
    var locationControlBackground: UIColor { UIColor.white.withAlphaComponent(0.5) }
    var locationControlButton: UIColor { .black }
    var locationControlBorder: UIColor { Self.lightGrayColor }
    var locationMapTint: UIColor { .black }
    var locationBubbleEmpty: UIColor { UIColor(white: 0.9, alpha: 1.0) }

    var scrollToBottomButtonTint: UIColor { .black }
    var scrollToBottomButtonBorder: UIColor { Self.lightGrayColor.withAlphaComponent(0.5) }
    var scrollToBottomButtonBackground: UIColor { .white }

    var voiceMessagePlayButton: UIColor { .white }
    var voiceMessageIncomePlayBackground: UIColor { Self.lightGrayColor }
    var voiceMessageOutcomePlayBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var voiceMessageIncomeTime: UIColor { Self.grayColor }
    var voiceMessageOutcomeTime: UIColor { Self.grayColor }
    var voiceMessageIncomeProgressMain: UIColor { .black }
    var voiceMessageIncomeProgressSecondary: UIColor { UIColor(hex: 0xe5e5e5) }
    var voiceMessageOutcomeProgressMain: UIColor { .white }
    var voiceMessageOutcomeProgressSecondary: UIColor { UIColor.white.withAlphaComponent(0.3) }

    var attachmentBadgeText: UIColor { .white }
    var attachmentBadgeBorder: UIColor { .clear }
    var attachmentBadgeBackground: UIColor { Self.grayColor }

    var imagePickerCheckMark: UIColor { .black }
    var imagePickerCheckMarkBackground: UIColor { .white }
    var imagePickerSelectionOverlay: UIColor { UIColor.black.withAlphaComponent(0.7) }
    var imagePickerPreviewBackground: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    var imagePickerAlbumTitle: UIColor { .black }
    var imagePickerAlbumCount: UIColor { Self.grayColor }
    var imagePickerBottomButtonTint: UIColor { .black }
    var imagePickerBottomButtonDisabledTint: UIColor { UIColor.black.withAlphaComponent(0.5) }
    var imagePickerButtonsBackground: UIColor { .white }
    var imagePickerBackground: UIColor { .white }
    var imagePickerButtonsBorderShadow: UIColor { Self.lightGrayColor }
    var imagePickerAlbumsSeparator: UIColor { Self.lightGrayColor }

    var imageBubbleEmpty: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    var imageBubbleProgress: UIColor { .white }
    var imageBubbleProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    var imageBubbleBlurColor: UIColor { UIColor.black.withAlphaComponent(0.3) }

    var documentButtonTint: UIColor { .white }
    var documentIncomeButtonBackground: UIColor { Self.lightGrayColor }
    var documentButtonOutcomeBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var documentIncomeProgressBackground: UIColor { UIColor.black.withAlphaComponent(0.9) }
    var documentProgressIncome: UIColor { .white }
    var documentIncomeProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    var documentOutcomeProgressBackground: UIColor { UIColor.white.withAlphaComponent(0.9) }
    var documentOutcomeProgress: UIColor { .black }
    var documentOutcomeProgressUntracked: UIColor { UIColor.black.withAlphaComponent(0.5) }

    var videoInfoBackground: UIColor { UIColor.black.withAlphaComponent(0.3) }
    var videoInfoMain: UIColor { .white }

    var replySwipeBackground: UIColor { UIColor.black.withAlphaComponent(0.2) }
    var replySwipeIcon: UIColor { .white }

    var attachmentsPreviewRemoveItemTint: UIColor { .white }

    var replyPreviewIcon: UIColor { Self.lightGrayColor }
    var replyPreviewNameText: UIColor { Self.grayColor }
    var replyPreviewReplyText: UIColor { .black }
    var replyPreviewRemoveButton: UIColor { .black }

    var navigationBarText: UIColor { .black }
    var navigationBarTint: UIColor { .black }

    var replyIncomeLineBackground: UIColor { .black }
    var replyIncomeNameText: UIColor { Self.grayColor }
    var replyIncomeContentText: UIColor { .black }
    var replyOutcomeLineBackground: UIColor { .white }
    var replyOutcomeNameText: UIColor { Self.grayColor }
    var replyOutcomeContentText: UIColor { .white }

    init() { }
}

class WRFImageSet: ThemeImageSet {
    lazy var chatBackground = UIImage.pch_fromColor(UIColor(hex: 0xf9f9f9))
}

class WRFStyleProvider: StyleProvider {
    var messagesCell: MessagesCellStyleProvider.Type { WRFMessagesCellStyleProvider.self }
}

class WRFFontProvider: FontProvider {
    var timeSeparator: UIFont { .wrfFont(ofSize: 13, weight: .light) }
    var locationPickTitle: UIFont { .wrfFont(ofSize: 16) }
    var locationPickSubtitle: UIFont { .wrfFont(ofSize: 12, weight: .light) }
    var badge: UIFont { .wrfFont(ofSize: 17) }
    var pickerVideoDuration: UIFont { .wrfFont(ofSize: 12) }
    var pickerAlbumTitle: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var pickerAlbumCount: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var pickerActionsButton: UIFont { .wrfFont(ofSize: 17) }
    var previewVideoDuration: UIFont { .wrfFont(ofSize: 12) }
    var voiceMessageRecordingTime: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var voiceMessageRecordingTitle: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var replyName: UIFont { .wrfFont(ofSize: 12, weight: .medium) }
    var replyText: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var senderPlaceholder: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var senderBadge: UIFont { .wrfFont(ofSize: 12) }
    var documentName: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var documentSize: UIFont { .wrfFont(ofSize: 12, weight: .light) }
    var videoInfoTime: UIFont { .wrfFont(ofSize: 11, weight: .light) }
    var contactTitle: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var contactPhone: UIFont { .wrfFont(ofSize: 12, weight: .light) }
    var voiceMessageDuration: UIFont { .wrfFont(ofSize: 11, weight: .light) }
    var messageText: UIFont { .wrfFont(ofSize: 16, weight: .light) }
    var messageInfoTime: UIFont { .wrfFont(ofSize: 12, weight: .light) }
    var messageReplyName: UIFont { .wrfFont(ofSize: 12, weight: .medium) }
    var messageReplyText: UIFont { .wrfFont(ofSize: 13, weight: .light) }
    var navigationTitle: UIFont { .wrfFont(ofSize: 17) }
    var navigationButton: UIFont { .wrfFont(ofSize: 17) }
}

class WRFLayoutProvider: LayoutProvider { }

enum WRFStyle {
    static let theme: Theme = {
        return Theme(
            palette: WRFPalette(),
            imageSet: WRFImageSet(),
            styleProvider: WRFStyleProvider(),
            fontProvider: WRFFontProvider(),
            layoutProvider: WRFLayoutProvider()
        )
    }()
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex & 0xff0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00ff00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000ff) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

private enum CustomFontName: String {
    case regular = "Ubuntu-Regular"
    case bold = "Ubuntu-Bold"
    case italic = "Ubuntu-Italic"
    case medium = "Ubuntu-Medium"
    case light = "Ubuntu-Light"
}

// swiftlint:disable force_unwrapping
private extension UIFont {
    class func wrfFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        switch weight {
        case UIFont.Weight.ultraLight, UIFont.Weight.light, UIFont.Weight.thin:
            return UIFont(name: CustomFontName.light.rawValue, size: size)!
        case UIFont.Weight.semibold, UIFont.Weight.medium:
            return UIFont(name: CustomFontName.medium.rawValue, size: size)!
        case UIFont.Weight.bold, UIFont.Weight.heavy, UIFont.Weight.black:
            return UIFont(name: CustomFontName.bold.rawValue, size: size)!
        default:
            return UIFont(name: CustomFontName.regular.rawValue, size: size)!
        }
    }

    class func wrfFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.regular.rawValue, size: size)!
    }

    @objc
    class func boldWRFFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.bold.rawValue, size: size)!
    }

    @objc
    class func italicWRFFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.italic.rawValue, size: size)!
    }
}
// swiftlint:enable force_unwrapping
