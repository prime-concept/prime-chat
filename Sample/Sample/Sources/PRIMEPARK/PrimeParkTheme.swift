import UIKit
import ChatSDK

class PrimeParkPalette: ThemePalette {
    static let brownColor = UIColor(hex: 0x807371)
    static let goldColor = UIColor(hex: 0xb3987a)
    static let darkBrownColor = UIColor(hex: 0x382823)
    static let lightGoldColor = UIColor(hex: 0xddcfbe)
    static let darkGoldColor = UIColor(hex: 0xaa8f59)

    var bubbleOutcomeBackground: UIColor { UIColor(hex: 0xad9478) }
    var bubbleOutcomeText: UIColor { UIColor.white.withAlphaComponent(0.8) }
    var bubbleOutcomeInfoTime: UIColor { UIColor.white.withAlphaComponent(0.8) }

    var bubbleIncomeBorder: UIColor { .clear }
    var bubbleOutcomeBorder: UIColor { .clear }
    
    var bubbleIncomeBackground: UIColor { UIColor(hex: 0x313131) }
    var bubbleIncomeText: UIColor { UIColor.white.withAlphaComponent(0.8) }
    var bubbleIncomeInfoTime: UIColor { UIColor(hex: 0x828082) }

    var bubbleBorder: UIColor { UIColor(hex: 0xd5d0cc) }
    var bubbleInfoPadBackground: UIColor { Self.darkBrownColor.withAlphaComponent(0.3) }
    var bubbleInfoPadText: UIColor { .white }

    var timeSeparatorText: UIColor { .white }
    var timeSeparatorBackground: UIColor { UIColor(hex: 0x313131) }

    var voiceMessageRecordingCircleTint: UIColor { .white }
    var voiceMessageRecordingCircleBackground: UIColor { UIColor(hex: 0x513932).withAlphaComponent(0.5) }
    var voiceMessageRecordingTime: UIColor { Self.darkBrownColor }
    var voiceMessageRecordingIndicator: UIColor { UIColor(hex: 0xcc2a21) }
    var voiceMessageRecordingDismissTitle: UIColor { Self.brownColor }
    var voiceMessageRecordingDismissIndicator: UIColor { Self.brownColor }

    var senderButton: UIColor { Self.goldColor }
    var senderBorderShadow: UIColor { .clear }
    var senderBackground: UIColor { UIColor(hex: 0x363636) }
    var senderPlaceholderColor: UIColor { UIColor(hex: 0x828082) }
    var senderTextColor: UIColor { .white }

    var contactIconIncomeBackground: UIColor { Self.lightGoldColor }
    var contactIconOutcomeBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var contactIcon: UIColor { UIColor.white }
    var contactIncomeTitle: UIColor { Self.darkBrownColor }
    var contactOutcomeTitle: UIColor { .white }
    var contactIncomePhone: UIColor { Self.brownColor }
    var contactOutcomePhone: UIColor { .white }

    var locationPickBackground: UIColor { .white }
    var locationPickTitle: UIColor { Self.darkBrownColor }
    var locationPickSubtitle: UIColor { Self.brownColor }
    var locationControlBackground: UIColor { UIColor.white.withAlphaComponent(0.5) }
    var locationControlButton: UIColor { Self.darkGoldColor }
    var locationControlBorder: UIColor { Self.lightGoldColor }
    var locationMapTint: UIColor { Self.darkGoldColor }
    var locationBubbleEmpty: UIColor { UIColor(white: 0.9, alpha: 1.0) }

    var scrollToBottomButtonTint: UIColor { Self.goldColor }
    var scrollToBottomButtonBorder: UIColor { Self.goldColor }
    var scrollToBottomButtonBackground: UIColor { .white }

    var voiceMessagePlayButton: UIColor { .white }
    var voiceMessageIncomePlayBackground: UIColor { Self.lightGoldColor }
    var voiceMessageOutcomePlayBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var voiceMessageIncomeTime: UIColor { Self.brownColor }
    var voiceMessageOutcomeTime: UIColor { UIColor.white.withAlphaComponent(0.8) }
    var voiceMessageIncomeProgressMain: UIColor { Self.darkGoldColor }
    var voiceMessageIncomeProgressSecondary: UIColor { Self.brownColor.withAlphaComponent(0.25) }
    var voiceMessageOutcomeProgressMain: UIColor { .white }
    var voiceMessageOutcomeProgressSecondary: UIColor { UIColor.white.withAlphaComponent(0.3) }

    var attachmentBadgeText: UIColor { .white }
    var attachmentBadgeBorder: UIColor { .clear }
    var attachmentBadgeBackground: UIColor { Self.goldColor }

    var imagePickerCheckMark: UIColor { Self.goldColor }
    var imagePickerCheckMarkBackground: UIColor { .white }
    var imagePickerSelectionOverlay: UIColor { Self.goldColor.withAlphaComponent(0.2) }
    var imagePickerPreviewBackground: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    var imagePickerAlbumTitle: UIColor { .white }
    var imagePickerAlbumCount: UIColor { UIColor(hex: 0x828082) }
    var imagePickerBottomButtonTint: UIColor { Self.goldColor }
    var imagePickerBottomButtonDisabledTint: UIColor { Self.goldColor }
    var imagePickerButtonsBackground: UIColor { UIColor(hex: 0x363636) }
    var imagePickerBackground: UIColor { UIColor(hex: 0x363636) }
    var imagePickerButtonsBorderShadow: UIColor { .clear }
    var imagePickerAlbumsSeparator: UIColor { UIColor(hex: 0xe6e6e6) }

    var imageBubbleEmpty: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    var imageBubbleProgress: UIColor { .white }
    var imageBubbleProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    var imageBubbleBlurColor: UIColor { Self.darkBrownColor.withAlphaComponent(0.5) }

    var documentButtonTint: UIColor { .white }
    var documentIncomeButtonBackground: UIColor { Self.lightGoldColor }
    var documentButtonOutcomeBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var documentIncomeProgressBackground: UIColor { Self.brownColor }
    var documentProgressIncome: UIColor { .white }
    var documentIncomeProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    var documentOutcomeProgressBackground: UIColor { UIColor.white.withAlphaComponent(0.9) }
    var documentOutcomeProgress: UIColor { Self.goldColor }
    var documentOutcomeProgressUntracked: UIColor { Self.goldColor.withAlphaComponent(0.5) }

    var videoInfoBackground: UIColor { Self.darkBrownColor.withAlphaComponent(0.3) }
    var videoInfoMain: UIColor { .white }

    var replySwipeBackground: UIColor { Self.brownColor.withAlphaComponent(0.2) }
    var replySwipeIcon: UIColor { Self.goldColor }

    var attachmentsPreviewRemoveItemTint: UIColor { .white }

    var replyPreviewIcon: UIColor { Self.lightGoldColor }
    var replyPreviewNameText: UIColor { Self.goldColor }
    var replyPreviewReplyText: UIColor { Self.darkBrownColor }
    var replyPreviewRemoveButton: UIColor { Self.goldColor }

    var navigationBarBackground: UIColor { UIColor(hex: 0x252525) }
    var navigationBarText: UIColor { .white }
    var navigationBarTint: UIColor { Self.goldColor }

    var replyIncomeLineBackground: UIColor { Self.goldColor }
    var replyIncomeNameText: UIColor { Self.goldColor }
    var replyIncomeContentText: UIColor { Self.darkBrownColor }
    var replyOutcomeLineBackground: UIColor { .white }
    var replyOutcomeNameText: UIColor { .white }
    var replyOutcomeContentText: UIColor { .white }

    init() { }
}

class PrimeParkImageSet: ThemeImageSet {
    lazy var chatBackground = UIImage.pch_fromColor(UIColor(hex: 0x121212))
}

class PrimeParkStyleProvider: StyleProvider {
    var messagesCell: MessagesCellStyleProvider.Type { PrimeParkMessagesCellStyleProvider.self }
}

class PrimeParkFontProvider: FontProvider {
    var timeSeparator: UIFont { .primeParkFont(ofSize: 11) }
    var locationPickTitle: UIFont { .primeParkFont(ofSize: 16) }
    var locationPickSubtitle: UIFont { .primeParkFont(ofSize: 12, weight: .light) }
    var badge: UIFont { .primeParkFont(ofSize: 17) }
    var pickerVideoDuration: UIFont { .primeParkFont(ofSize: 12) }
    var pickerAlbumTitle: UIFont { .primeParkFont(ofSize: 14) }
    var pickerAlbumCount: UIFont { .primeParkFont(ofSize: 16, weight: .medium) }
    var pickerActionsButton: UIFont { .primeParkFont(ofSize: 14, weight: .medium) }
    var previewVideoDuration: UIFont { .primeParkFont(ofSize: 12) }
    var voiceMessageRecordingTime: UIFont { .primeParkFont(ofSize: 16, weight: .light) }
    var voiceMessageRecordingTitle: UIFont { .primeParkFont(ofSize: 16, weight: .light) }
    var replyName: UIFont { .primeParkFont(ofSize: 12, weight: .medium) }
    var replyText: UIFont { .primeParkFont(ofSize: 16, weight: .light) }
    var senderPlaceholder: UIFont { .primeParkFont(ofSize: 14) }
    var senderBadge: UIFont { .primeParkFont(ofSize: 12) }
    var documentName: UIFont { .primeParkFont(ofSize: 16, weight: .light) }
    var documentSize: UIFont { .primeParkFont(ofSize: 12, weight: .light) }
    var videoInfoTime: UIFont { .primeParkFont(ofSize: 11, weight: .light) }
    var contactTitle: UIFont { .primeParkFont(ofSize: 16, weight: .light) }
    var contactPhone: UIFont { .primeParkFont(ofSize: 12, weight: .light) }
    var voiceMessageDuration: UIFont { .primeParkFont(ofSize: 11, weight: .light) }
    var messageText: UIFont { .primeParkFont(ofSize: 16) }
    var messageInfoTime: UIFont { .primeParkFont(ofSize: 11) }
    var messageReplyName: UIFont { .primeParkFont(ofSize: 12, weight: .medium) }
    var messageReplyText: UIFont { .primeParkFont(ofSize: 13, weight: .light) }
    var navigationTitle: UIFont { .primeParkFont(ofSize: 17, weight: .medium) }
    var navigationButton: UIFont { .primeParkFont(ofSize: 17) }
}

class PrimeParkLayoutProvider: LayoutProvider { }

enum PrimeParkStyle {
    static let theme: Theme = {
        return Theme(
            palette: PrimeParkPalette(),
            imageSet: PrimeParkImageSet(),
            styleProvider: PrimeParkStyleProvider(),
            fontProvider: PrimeParkFontProvider(),
            layoutProvider: PrimeParkLayoutProvider()
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
    class func primeParkFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
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

    class func primeParkFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.regular.rawValue, size: size)!
    }

    @objc
    class func boldPrimeParkFontFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.bold.rawValue, size: size)!
    }

    @objc
    class func italicPrimeParkFontFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.italic.rawValue, size: size)!
    }
}
// swiftlint:enable force_unwrapping
