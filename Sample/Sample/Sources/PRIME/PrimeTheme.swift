import UIKit
import ChatSDK

class PrimePalette: ThemePalette {
    static let brownColor = UIColor(hex: 0x807371)
    static let goldColor = UIColor(hex: 0xc8ad7d)
    static let darkBrownColor = UIColor(hex: 0x382823)
    static let lightGoldColor = UIColor(hex: 0xddcfbe)
    static let darkGoldColor = UIColor(hex: 0xaa8f59)

    var bubbleOutcomeBackground: UIColor { Self.brownColor }
    var bubbleOutcomeText: UIColor { .white }
    var bubbleOutcomeInfoTime: UIColor { UIColor.white.withAlphaComponent(0.8) }

    var bubbleIncomeBorder: UIColor { .clear }
    var bubbleOutcomeBorder: UIColor { .clear }
    
    var bubbleIncomeBackground: UIColor { .white }
    var bubbleIncomeText: UIColor { .black }
    var bubbleIncomeInfoTime: UIColor { Self.brownColor }

    var bubbleBorder: UIColor { UIColor(hex: 0xd5d0cc) }
    var bubbleInfoPadBackground: UIColor { Self.darkBrownColor.withAlphaComponent(0.3) }
    var bubbleInfoPadText: UIColor { .white }

    var timeSeparatorText: UIColor { .white }
    var timeSeparatorBackground: UIColor { Self.brownColor.withAlphaComponent(0.3) }

    var voiceMessageRecordingCircleTint: UIColor { .white }
    var voiceMessageRecordingCircleBackground: UIColor { UIColor(hex: 0x513932).withAlphaComponent(0.5) }
    var voiceMessageRecordingTime: UIColor { Self.darkBrownColor }
    var voiceMessageRecordingIndicator: UIColor { UIColor(hex: 0xcc2a21) }
    var voiceMessageRecordingDismissTitle: UIColor { Self.brownColor }
    var voiceMessageRecordingDismissIndicator: UIColor { Self.brownColor }

    var senderButton: UIColor { Self.goldColor }
    var senderBorderShadow: UIColor { Self.lightGoldColor }
    var senderBackground: UIColor { .white }
    var senderPlaceholderColor: UIColor { Self.brownColor.withAlphaComponent(0.5) }
    var senderTextColor: UIColor { Self.darkBrownColor }

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
    var attachmentBadgeBorder: UIColor { .white }
    var attachmentBadgeBackground: UIColor { Self.goldColor }

    var imagePickerCheckMark: UIColor { Self.darkBrownColor }
    var imagePickerCheckMarkBackground: UIColor { .white }
    var imagePickerSelectionOverlay: UIColor { Self.darkBrownColor.withAlphaComponent(0.7) }
    var imagePickerPreviewBackground: UIColor { UIColor(white: 0.9, alpha: 1.0) }
    var imagePickerAlbumTitle: UIColor { Self.darkBrownColor }
    var imagePickerAlbumCount: UIColor { Self.brownColor }
    var imagePickerBottomButtonTint: UIColor { Self.darkBrownColor }
    var imagePickerBottomButtonDisabledTint: UIColor { Self.brownColor.withAlphaComponent(0.5) }
    var imagePickerButtonsBackground: UIColor { .white }
    var imagePickerBackground: UIColor { .white }
    var imagePickerButtonsBorderShadow: UIColor { Self.lightGoldColor }
    var imagePickerAlbumsSeparator: UIColor { Self.lightGoldColor }

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
    var replySwipeIcon: UIColor { .white }

    var attachmentsPreviewRemoveItemTint: UIColor { .white }

    var replyPreviewIcon: UIColor { Self.lightGoldColor }
    var replyPreviewNameText: UIColor { Self.goldColor }
    var replyPreviewReplyText: UIColor { Self.darkBrownColor }
    var replyPreviewRemoveButton: UIColor { Self.goldColor }

    var navigationBarText: UIColor { Self.darkBrownColor }
    var navigationBarTint: UIColor { Self.darkBrownColor }

    var replyIncomeLineBackground: UIColor { Self.goldColor }
    var replyIncomeNameText: UIColor { Self.goldColor }
    var replyIncomeContentText: UIColor { Self.darkBrownColor }
    var replyOutcomeLineBackground: UIColor { .white }
    var replyOutcomeNameText: UIColor { .white }
    var replyOutcomeContentText: UIColor { .white }

    init() { }
}

class PrimeImageSet: ThemeImageSet {
    lazy var chatBackground = UIImage.pch_fromColor(UIColor(hex: 0xf6f1eb))
}

class PrimeStyleProvider: StyleProvider {
    var messagesCell: MessagesCellStyleProvider.Type { PrimeMessagesCellStyleProvider.self }
}

class PrimeFontProvider: FontProvider { }

class PrimeLayoutProvider: LayoutProvider { }

enum PrimeStyle {
    static let theme: Theme = {
        return Theme(
            palette: PrimePalette(),
            imageSet: PrimeImageSet(),
            styleProvider: PrimeStyleProvider(),
            fontProvider: PrimeFontProvider(),
            layoutProvider: PrimeLayoutProvider()
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
