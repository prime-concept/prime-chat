import UIKit
import ChatSDK

private enum Palette {
    static let darkColor = UIColor(hex: 0x363636)
    static let darkLightColor = UIColor(hex: 0x828082)
    static let secondBlack = UIColor(hex: 0x121212)
    static let mainRed = UIColor(hex: 0xa1330a)
    static let secondGold = UIColor(hex: 0xaa8f59)
    static let burgundyColor = UIColor(hex: 0x5a2f23)
    static let mainGold = UIColor(hex: 0xc8ad7d)
    static let mainBlack = UIColor(hex: 0x382823)
    static let gray = UIColor(hex: 0x808080)
    static let middleGray = UIColor(hex: 0xdbdbdb)
    static let nobleBrown = UIColor(hex: 0x340f06)
    static let lightGray = UIColor(hex: 0xf6f5f3)
    static let darkGold = UIColor(hex: 0xaa8e58)
}

final class PrimeAppPalette: ThemePalette {
    var bubbleOutcomeBackground: UIColor { Palette.mainGold }
    var bubbleOutcomeText: UIColor { .white }
    var bubbleOutcomeInfoTime: UIColor { UIColor.white.withAlphaComponent(0.9) }

    var bubbleIncomeBorder: UIColor { Palette.middleGray }
    var bubbleOutcomeBorder: UIColor { .clear }

    var bubbleIncomeBackground: UIColor { .white }
    var bubbleIncomeText: UIColor { Palette.nobleBrown }
    var bubbleIncomeInfoTime: UIColor { Palette.gray }

    var bubbleBorder: UIColor { Palette.middleGray }
    var bubbleInfoPadBackground: UIColor { Palette.nobleBrown.withAlphaComponent(0.3) }
    var bubbleInfoPadText: UIColor { .white }

    var timeSeparatorText: UIColor { .white }
    var timeSeparatorBackground: UIColor { UIColor(hex: 0x807371).withAlphaComponent(0.3) }

    var voiceMessageRecordingCircleTint: UIColor { .white }
    var voiceMessageRecordingCircleBackground: UIColor { Palette.mainGold.withAlphaComponent(0.5) }
    var voiceMessageRecordingTime: UIColor { Palette.nobleBrown }
    var voiceMessageRecordingIndicator: UIColor { Palette.mainRed }
    var voiceMessageRecordingDismissTitle: UIColor { Palette.gray }
    var voiceMessageRecordingDismissIndicator: UIColor { Palette.gray }

    var senderButton: UIColor { Palette.darkGold }
    var senderBorderShadow: UIColor { Palette.middleGray }
    var senderBackground: UIColor { .white }
    var senderPlaceholderColor: UIColor { Palette.gray }
    var senderTextColor: UIColor { Palette.nobleBrown }

    var contactIconIncomeBackground: UIColor { Palette.mainGold }
    var contactIconOutcomeBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var contactIcon: UIColor { UIColor.white }
    var contactIncomeTitle: UIColor { Palette.nobleBrown }
    var contactOutcomeTitle: UIColor { .white }
    var contactIncomePhone: UIColor { Palette.gray }
    var contactOutcomePhone: UIColor { .white }

    var locationPickBackground: UIColor { .white }
    var locationPickTitle: UIColor { Palette.nobleBrown }
    var locationPickSubtitle: UIColor { Palette.gray }
    var locationControlBackground: UIColor { Palette.middleGray.withAlphaComponent(0.5) }
    var locationControlButton: UIColor { Palette.mainGold }
    var locationControlBorder: UIColor { Palette.mainGold }
    var locationMapTint: UIColor { Palette.mainRed }
    var locationBubbleEmpty: UIColor { UIColor(white: 0.9, alpha: 1.0) }

    var scrollToBottomButtonTint: UIColor { Palette.mainGold }
    var scrollToBottomButtonBorder: UIColor { Palette.mainGold }
    var scrollToBottomButtonBackground: UIColor { .white }

    var voiceMessagePlayButton: UIColor { .white }
    var voiceMessageIncomePlayBackground: UIColor { Palette.mainGold }
    var voiceMessageOutcomePlayBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var voiceMessageIncomeTime: UIColor { Palette.gray }
    var voiceMessageOutcomeTime: UIColor { UIColor.white.withAlphaComponent(0.9) }
    var voiceMessageIncomeProgressMain: UIColor { Palette.mainGold }
    var voiceMessageIncomeProgressSecondary: UIColor { Palette.mainGold.withAlphaComponent(0.3) }
    var voiceMessageOutcomeProgressMain: UIColor { .white }
    var voiceMessageOutcomeProgressSecondary: UIColor { UIColor.white.withAlphaComponent(0.3) }

    var attachmentBadgeText: UIColor { .white }
    var attachmentBadgeBorder: UIColor { .white }
    var attachmentBadgeBackground: UIColor { Palette.mainGold }

    var imagePickerCheckMark: UIColor { Palette.nobleBrown }
    var imagePickerCheckMarkBackground: UIColor { .white }
    var imagePickerSelectionOverlay: UIColor { Palette.nobleBrown.withAlphaComponent(0.7) }
    var imagePickerPreviewBackground: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    var imagePickerAlbumTitle: UIColor { Palette.nobleBrown }
    var imagePickerAlbumCount: UIColor { Palette.gray }
    var imagePickerBottomButtonTint: UIColor { Palette.nobleBrown }
    var imagePickerBottomButtonDisabledTint: UIColor { Palette.nobleBrown.withAlphaComponent(0.5) }
    var imagePickerButtonsBackground: UIColor { .white }
    var imagePickerBackground: UIColor { .white }
    var imagePickerButtonsBorderShadow: UIColor { Palette.gray }
    var imagePickerAlbumsSeparator: UIColor { Palette.middleGray }

    var imageBubbleEmpty: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    var imageBubbleProgress: UIColor { .white }
    var imageBubbleProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    var imageBubbleBlurColor: UIColor { Palette.mainBlack.withAlphaComponent(0.5) }

    var documentButtonTint: UIColor { .white }
    var documentButtonIncomeBackground: UIColor { Palette.mainGold }
    var documentButtonOutcomeBackground: UIColor { UIColor.white.withAlphaComponent(0.25) }
    var documentIncomeProgressBackground: UIColor { Palette.mainGold }
    var documentProgressIncome: UIColor { .white }
    var documentIncomeProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    var documentOutcomeProgressBackground: UIColor { .white }
    var documentOutcomeProgress: UIColor { Palette.mainGold }
    var documentOutcomeProgressUntracked: UIColor { Palette.mainGold.withAlphaComponent(0.5) }

    var videoInfoBackground: UIColor { Palette.nobleBrown.withAlphaComponent(0.3) }
    var videoInfoMain: UIColor { .white }

    var replySwipeBackground: UIColor { UIColor(hex: 0x807371).withAlphaComponent(0.25) }
    var replySwipeIcon: UIColor { .white }

    var attachmentsPreviewRemoveItemTint: UIColor { .white }

    var replyPreviewIcon: UIColor { Palette.gray.withAlphaComponent(0.5) }
    var replyPreviewNameText: UIColor { Palette.mainGold }
    var replyPreviewReplyText: UIColor { Palette.nobleBrown }
    var replyPreviewRemoveButton: UIColor { Palette.mainGold }

    var navigationBarText: UIColor { Palette.nobleBrown }
    var navigationBarTint: UIColor { Palette.nobleBrown }

    var replyIncomeLineBackground: UIColor { Palette.mainGold }
    var replyIncomeNameText: UIColor { Palette.mainGold }
    var replyIncomeContentText: UIColor { Palette.nobleBrown }
    var replyOutcomeLineBackground: UIColor { .white }
    var replyOutcomeNameText: UIColor { .white }
    var replyOutcomeContentText: UIColor { .white }

    init() { }
}

final class PrimeAppImageSet: ThemeImageSet {
    private(set) lazy var chatBackground: UIImage = UIImage.pch_fromColor(Palette.lightGray)
    private(set) lazy var attachPickersButton: UIImage = UIImage(named: "chat_attach_icon") ?? UIImage()
    private(set) lazy var sendMessageButton: UIImage = UIImage(named: "chat_send_icon") ?? UIImage()
    private(set) lazy var voiceMessageButton: UIImage = UIImage(named: "chat_voice_icon") ?? UIImage()
}

final class PrimeAppStyleProvider: StyleProvider {
    var messagesCell: MessagesCellStyleProvider.Type { PrimeAppMessagesCellStyleProvider.self }
}

final class PrimeAppFontProvider: FontProvider {
    private static let regular11 = FontDescriptor(font: .primeFont(ofSize: 11), lineHeight: 11)
    private static let regular12 = FontDescriptor(font: .primeFont(ofSize: 12), lineHeight: 14, baselineOffset: 1.0)
    private static let regular15 = FontDescriptor(font: .primeFont(ofSize: 15), lineHeight: 19, baselineOffset: 1.0)

    let timeSeparator: FontDescriptor = PrimeAppFontProvider.regular12
    let locationPickTitle: FontDescriptor = PrimeAppFontProvider.regular15
    let locationPickSubtitle: FontDescriptor = PrimeAppFontProvider.regular11

    var badge: FontDescriptor { UIFont.primeFont(ofSize: 15).pch_fontDescriptor }

    var pickerVideoDuration: FontDescriptor { UIFont.primeFont(ofSize: 12).pch_fontDescriptor }
    var pickerAlbumTitle: FontDescriptor { UIFont.primeFont(ofSize: 15).pch_fontDescriptor }
    var pickerAlbumCount: FontDescriptor { UIFont.primeFont(ofSize: 15).pch_fontDescriptor }
    var pickerActionsButton: FontDescriptor { UIFont.primeFont(ofSize: 15).pch_fontDescriptor }

    var previewVideoDuration: FontDescriptor { UIFont.primeFont(ofSize: 12).pch_fontDescriptor }

    let voiceMessageRecordingTime: FontDescriptor = PrimeAppFontProvider.regular15
    let voiceMessageRecordingTitle: FontDescriptor = PrimeAppFontProvider.regular15

    let replyName: FontDescriptor = PrimeAppFontProvider.regular12
    let replyText: FontDescriptor = PrimeAppFontProvider.regular15
    let senderPlaceholder: FontDescriptor = PrimeAppFontProvider.regular15
    var senderBadge: FontDescriptor { UIFont.primeFont(ofSize: 12).pch_fontDescriptor }
    let documentName: FontDescriptor = PrimeAppFontProvider.regular15
    var documentSize: FontDescriptor = PrimeAppFontProvider.regular11
    let videoInfoTime: FontDescriptor = PrimeAppFontProvider.regular11
    let contactTitle: FontDescriptor = PrimeAppFontProvider.regular15
    let contactPhone: FontDescriptor = PrimeAppFontProvider.regular11
    let voiceMessageDuration: FontDescriptor = PrimeAppFontProvider.regular11
    let messageText: FontDescriptor = PrimeAppFontProvider.regular15
    let messageInfoTime: FontDescriptor = PrimeAppFontProvider.regular11

    var messageReplyName: FontDescriptor {
        FontDescriptor(font: .primeFont(ofSize: 12, weight: .medium), lineHeight: 13, baselineOffset: 1.0)
    }
    let messageReplyText: FontDescriptor = PrimeAppFontProvider.regular12

    var navigationTitle: FontDescriptor { UIFont.primeFont(ofSize: 16, weight: .medium).pch_fontDescriptor }
    var navigationButton: FontDescriptor { UIFont.primeFont(ofSize: 15).pch_fontDescriptor }
}

final class PrimeAppLayoutProvider: LayoutProvider {
    var textNormalMessageInsets: UIEdgeInsets { .init(top: 10, left: 15, bottom: 12, right: 15) }
    var textReplyMessageInsets: UIEdgeInsets { .init(top: 8, left: 15, bottom: 12, right: 15) }
    var videoInfoPlayImageRightMargin: CGFloat { 6.0 }
}

enum PrimeAppStyle {
    static let theme: Theme = {
        return Theme(
            palette: PrimeAppPalette(),
            imageSet: PrimeAppImageSet(),
            styleProvider: PrimeAppStyleProvider(),
            fontProvider: PrimeAppFontProvider(),
            layoutProvider: PrimeAppLayoutProvider()
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
    case regular = "GothamPro"
    case bold = "GothamPro-Bold"
    case italic = "GothamPro-Italic"
    case medium = "GothamPro-Medium"
    case light = "GothamPro-Light"
}

// swiftlint:disable force_unwrapping
private extension UIFont {
    class func primeFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
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

    class func primeFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.regular.rawValue, size: size)!
    }

    @objc
    class func boldPrimeFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.bold.rawValue, size: size)!
    }

    @objc
    class func italicPrimeFont(ofSize size: CGFloat) -> UIFont {
        return UIFont(name: CustomFontName.italic.rawValue, size: size)!
    }
}
// swiftlint:enable force_unwrapping
