import UIKit

/// Representation of appearance scheme (colors, icons, etc)
public struct Theme {
    /// Colors of given theme
    public var palette: ThemePalette

    /// Images of given theme
    public var imageSet: ThemeImageSet

    /// Style provider
    public var styleProvider: StyleProvider

    /// Font provider
    public var fontProvider: FontProvider

    /// Layout provider
    public var layoutProvider: LayoutProvider

    /// Default theme
    public static var `default` = Theme(
        palette: DefaultPalette(),
        imageSet: DefaultImageSet(),
        styleProvider: DefaultStyleProvider(),
        fontProvider: DefaultFontProvider(),
        layoutProvider: DefaultLayoutProvider()
    )

    public init(
        palette: ThemePalette,
        imageSet: ThemeImageSet,
        styleProvider: StyleProvider,
        fontProvider: FontProvider,
        layoutProvider: LayoutProvider
    ) {
        self.palette = palette
        self.imageSet = imageSet
        self.styleProvider = styleProvider
        self.fontProvider = fontProvider
        self.layoutProvider = layoutProvider
    }

    // MARK: - Inner declaration

    private class DefaultPalette: ThemePalette {
        init() { }
    }

    private class DefaultImageSet: ThemeImageSet {
        init() { }
    }

    private class DefaultStyleProvider: StyleProvider {
        init() { }
    }

    private class DefaultFontProvider: FontProvider {
        init() { }
    }

    private class DefaultLayoutProvider: LayoutProvider {
        init() { }
    }
}

// MARK: - Palette

private extension UIColor {
    static let defaultBlue = UIColor(red: 0 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1)
}

/// Container for colors of some Theme
public protocol ThemePalette {
    var bubbleOutcomeBackground: UIColor { get }
    var bubbleOutcomeBorder: UIColor { get }
    var bubbleOutcomeText: UIColor { get }
    var bubbleIncomeBackground: UIColor { get }
    var bubbleIncomeBorder: UIColor { get }
    var bubbleIncomeText: UIColor { get }
    var bubbleIncomeInfoTime: UIColor { get }
    var bubbleOutcomeInfoTime: UIColor { get }
    var bubbleInfoStatusIcon: UIColor { get }
    var bubbleBorder: UIColor { get }
    var bubbleInfoPadBackground: UIColor { get }
    var bubbleInfoPadText: UIColor { get }
    var timeSeparatorText: UIColor { get }
    var timeSeparatorBackground: UIColor { get }
    var voiceMessageRecordingCircleTint: UIColor { get }
    var voiceMessageRecordingCircleBackground: UIColor { get }
    var voiceMessageRecordingTime: UIColor { get }
    var voiceMessageRecordingIndicator: UIColor { get }
    var voiceMessageRecordingDismissIndicator: UIColor { get }
    var voiceMessageRecordingDismissTitle: UIColor { get }
    var senderButton: UIColor { get }
    var senderBorderShadow: UIColor { get }
    var senderBackground: UIColor { get }
    var senderPlaceholderColor: UIColor { get }
    var senderTextColor: UIColor { get }
    var contactIconIncomeBackground: UIColor { get }
    var contactIconOutcomeBackground: UIColor { get }
    var contactIncomeTitle: UIColor { get }
    var contactOutcomeTitle: UIColor { get }
    var contactIncomePhone: UIColor { get }
    var contactOutcomePhone: UIColor { get }
    var locationPickBackground: UIColor { get }
    var locationPickTitle: UIColor { get }
    var locationPickSubtitle: UIColor { get }
    var locationControlBackground: UIColor { get }
    var locationControlButton: UIColor { get }
    var locationControlBorder: UIColor { get }
    var locationMapTint: UIColor { get }
    var locationBubbleEmpty: UIColor { get }
    var attachmentBadgeText: UIColor { get }
    var attachmentBadgeBorder: UIColor { get }
    var attachmentBadgeBackground: UIColor { get }
    var scrollToBottomButtonTint: UIColor { get }
    var scrollToBottomButtonBackground: UIColor { get }
    var scrollToBottomButtonBorder: UIColor { get }
    var voiceMessagePlayButton: UIColor { get }
    var voiceMessageIncomePlayBackground: UIColor { get }
    var voiceMessageOutcomePlayBackground: UIColor { get }
    var voiceMessageIncomeTime: UIColor { get }
    var voiceMessageOutcomeTime: UIColor { get }
    var voiceMessageIncomeProgressMain: UIColor { get }
    var voiceMessageIncomeProgressSecondary: UIColor { get }
    var voiceMessageOutcomeProgressMain: UIColor { get }
    var voiceMessageOutcomeProgressSecondary: UIColor { get }
    var imagePickerCheckMark: UIColor { get }
    var imagePickerCheckMarkBackground: UIColor { get }
    var imagePickerSelectionOverlay: UIColor { get }
    var imagePickerPreviewBackground: UIColor { get }
    var imagePickerAlbumTitle: UIColor { get }
    var imagePickerAlbumCount: UIColor { get }
    var imagePickerBottomButtonTint: UIColor { get }
    var imagePickerBottomButtonDisabledTint: UIColor { get }
    var imagePickerButtonsBackground: UIColor { get }
    var imagePickerBackground: UIColor { get }
    var imagePickerAlbumsSeparator: UIColor { get }
    var imagePickerButtonsBorderShadow: UIColor { get }
    var imagePickerItemDuration: UIColor { get }
    var imageBubbleEmpty: UIColor { get }
    var imageBubbleProgress: UIColor { get }
    var imageBubbleProgressUntracked: UIColor { get }
    var imageBubbleBlurColor: UIColor { get }
    var videoInfoMain: UIColor { get }
    var videoInfoBackground: UIColor { get }
    var documentButtonTint: UIColor { get }
    var documentButtonIncomeBackground: UIColor { get }
    var documentButtonOutcomeBackground: UIColor { get }
    var documentIncomeProgressBackground: UIColor { get }
    var documentIncomeProgress: UIColor { get }
    var documentIncomeProgressUntracked: UIColor { get }
    var documentOutcomeProgressBackground: UIColor { get }
    var documentOutcomeProgress: UIColor { get }
    var documentOutcomeProgressUntracked: UIColor { get }
    var replySwipeBackground: UIColor { get }
    var replySwipeIcon: UIColor { get }
    var attachmentsPreviewRemoveItemTint: UIColor { get }
    var replyPreviewIcon: UIColor { get }
    var replyPreviewRemoveButton: UIColor { get }
    var replyPreviewNameText: UIColor { get }
    var replyPreviewReplyText: UIColor { get }
    var navigationBarBackground: UIColor { get }
    var navigationBarText: UIColor { get }
    var navigationBarTint: UIColor { get }
    var pickerAlertControllerTint: UIColor? { get }
    var replyIncomeLineBackground: UIColor { get }
    var replyIncomeNameText: UIColor { get }
    var replyIncomeContentText: UIColor { get }
    var replyOutcomeLineBackground: UIColor { get }
    var replyOutcomeNameText: UIColor { get }
    var replyOutcomeContentText: UIColor { get }
    var fullImageCloseButtonTintColor: UIColor { get }
    var fullImageCloseButtonBackgroundColor: UIColor { get }
    var textContentOutcomeLinkColor: UIColor? { get }
    var textContentIncomeLinkColor: UIColor? { get }
}

// swiftlint:disable line_length
extension ThemePalette {
    public var bubbleOutcomeBackground: UIColor { .defaultBlue }
    public var bubbleIncomeBackground: UIColor { .defaultBlue }
    public var bubbleIncomeBorder: UIColor { .clear }
    public var bubbleOutcomeBorder: UIColor { .clear }
    public var bubbleIncomeText: UIColor { .white }
    public var bubbleOutcomeText: UIColor { .white }
    public var bubbleIncomeInfoTime: UIColor { .white }
    public var bubbleOutcomeInfoTime: UIColor { .white }
    public var bubbleInfoStatusIcon: UIColor { .white }
    public var bubbleBorder: UIColor { .lightGray }
    public var bubbleInfoPadBackground: UIColor { UIColor.lightGray.withAlphaComponent(0.3) }
    public var bubbleInfoPadText: UIColor { .white }
    public var timeSeparatorText: UIColor { .lightGray }
    public var timeSeparatorBackground: UIColor { .white }
    public var senderButton: UIColor { UIColor(red: 0 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1) }
    public var senderBorderShadow: UIColor { UIColor.black.withAlphaComponent(0.3) }
    public var voiceMessageRecordingCircleTint: UIColor { .white }
    public var voiceMessageRecordingCircleBackground: UIColor { UIColor.defaultBlue.withAlphaComponent(0.5) }
    public var voiceMessageRecordingTime: UIColor { .black }
    public var voiceMessageRecordingIndicator: UIColor { .red }
    public var voiceMessageRecordingDismissTitle: UIColor { .black }
    public var voiceMessageRecordingDismissIndicator: UIColor { .black }
    public var senderBackground: UIColor { UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0) }
    public var senderPlaceholderColor: UIColor { .lightGray }
    public var senderTextColor: UIColor { .black }
    public var scrollToBottomButtonTint: UIColor { UIColor(red: 0 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1) }
    public var scrollToBottomButtonBackground: UIColor { .white }
    public var scrollToBottomButtonBorder: UIColor { UIColor(red: 0 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1) }
    public var contactIconIncomeBackground: UIColor { UIColor.white.withAlphaComponent(0.2) }
    public var contactIconOutcomeBackground: UIColor { UIColor.white.withAlphaComponent(0.2) }
    public var contactIcon: UIColor { .white }
    public var contactIncomeTitle: UIColor { .white }
    public var contactOutcomeTitle: UIColor { .white }
    public var contactIncomePhone: UIColor { .white }
    public var contactOutcomePhone: UIColor { .white }
    public var locationPickBackground: UIColor { .white }
    public var locationPickTitle: UIColor { .black }
    public var locationPickSubtitle: UIColor { .black }
    public var locationControlBackground: UIColor { UIColor.white.withAlphaComponent(0.5) }
    public var locationControlButton: UIColor { .defaultBlue }
    public var locationControlBorder: UIColor { .clear }
    public var locationMapTint: UIColor { .defaultBlue }
    public var locationBubbleEmpty: UIColor { .lightGray }
    public var attachmentBadgeText: UIColor { .white }
    public var attachmentBadgeBorder: UIColor { .white }
    public var attachmentBadgeBackground: UIColor { .defaultBlue }
    public var voiceMessagePlayButton: UIColor { .white }
    public var voiceMessageIncomePlayBackground: UIColor { UIColor.white.withAlphaComponent(0.3) }
    public var voiceMessageOutcomePlayBackground: UIColor { UIColor.white.withAlphaComponent(0.3) }
    public var voiceMessageIncomeTime: UIColor { .white }
    public var voiceMessageOutcomeTime: UIColor { .white }
    public var voiceMessageIncomeProgressMain: UIColor { .white }
    public var voiceMessageIncomeProgressSecondary: UIColor { UIColor.white.withAlphaComponent(0.3) }
    public var voiceMessageOutcomeProgressMain: UIColor { .white }
    public var voiceMessageOutcomeProgressSecondary: UIColor { UIColor.white.withAlphaComponent(0.3) }
    public var imagePickerCheckMark: UIColor { .defaultBlue }
    public var imagePickerCheckMarkBackground: UIColor { .white }
    public var imagePickerSelectionOverlay: UIColor { UIColor.white.withAlphaComponent(0.5) }
    public var imagePickerPreviewBackground: UIColor { .lightGray }
    public var imagePickerAlbumTitle: UIColor { .black }
    public var imagePickerAlbumCount: UIColor { .defaultBlue }
    public var imagePickerBottomButtonTint: UIColor { .defaultBlue }
    public var imagePickerBottomButtonDisabledTint: UIColor { UIColor.defaultBlue.withAlphaComponent(0.5) }
    public var imagePickerButtonsBackground: UIColor { .white }
    public var imagePickerBackground: UIColor { .white }
    public var imagePickerButtonsBorderShadow: UIColor { UIColor.black.withAlphaComponent(0.3) }
    public var imagePickerAlbumsSeparator: UIColor { .lightGray }
    public var imagePickerItemDuration: UIColor { .white }
    public var imageBubbleEmpty: UIColor { .lightGray }
    public var imageBubbleProgress: UIColor { .white }
    public var imageBubbleProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    public var imageBubbleBlurColor: UIColor { .clear }
    public var videoInfoMain: UIColor { .white }
    public var videoInfoBackground: UIColor { UIColor.lightGray.withAlphaComponent(0.3) }
    public var documentButtonTint: UIColor { .white }
    public var documentButtonIncomeBackground: UIColor { UIColor.white.withAlphaComponent(0.3) }
    public var documentButtonOutcomeBackground: UIColor { UIColor.white.withAlphaComponent(0.3) }
    public var documentIncomeProgressBackground: UIColor { UIColor.white.withAlphaComponent(0.3) }
    public var documentIncomeProgress: UIColor { .white }
    public var documentIncomeProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    public var documentOutcomeProgressBackground: UIColor { UIColor.white.withAlphaComponent(0.3) }
    public var documentOutcomeProgress: UIColor { .white }
    public var documentOutcomeProgressUntracked: UIColor { UIColor.white.withAlphaComponent(0.5) }
    public var replySwipeBackground: UIColor { .lightGray }
    public var replySwipeIcon: UIColor { .white }
    public var attachmentsPreviewRemoveItemTint: UIColor { .white }
    public var replyPreviewIcon: UIColor { .defaultBlue }
    public var replyPreviewRemoveButton: UIColor { .defaultBlue }
    public var replyPreviewNameText: UIColor { .lightGray }
    public var replyPreviewReplyText: UIColor { .black }
    public var navigationBarBackground: UIColor { .white }
    public var navigationBarText: UIColor { .black }
    public var navigationBarTint: UIColor { .black }
    public var pickerAlertControllerTint: UIColor? { nil }
    public var replyIncomeLineBackground: UIColor { .white }
    public var replyIncomeNameText: UIColor { .white }
    public var replyIncomeContentText: UIColor { .white }
    public var replyOutcomeLineBackground: UIColor { .white }
    public var replyOutcomeNameText: UIColor { .white }
    public var replyOutcomeContentText: UIColor { .white }
    public var fullImageCloseButtonTintColor: UIColor { .white.withAlphaComponent(0.5) }
    public var fullImageCloseButtonBackgroundColor: UIColor {
        let value = CGFloat(0x80) / 0xFF
        return UIColor(red: value, green: value, blue: value, alpha: 0.5)
    }
    public var textContentOutcomeLinkColor: UIColor? { nil }
    public var textContentIncomeLinkColor: UIColor? { nil }
}
// swiftlint:enable line_length

// MARK: - ImageSet

/// Container for images of some Theme
public protocol ThemeImageSet {
    var chatBackground: UIImage { get }
    var statusSentUnreadMessage: UIImage { get }
    var statusSentReadMessage: UIImage { get }
    var statusSendingMessage: UIImage { get }
    var errorButton: UIImage { get }
    var slideToCancelIndicatorIcon: UIImage { get }
    var sendMessageButton: UIImage { get }
    var attachPickersButton: UIImage { get }
    var voiceMessageButton: UIImage { get }
    var voiceMessagePlayButton: UIImage { get }
    var voiceMessagePauseButton: UIImage { get }
    var contactBubbleIcon: UIImage { get }
    var locationPin: UIImage { get }
    var locationInfoButton: UIImage { get }
    var locationPositionButton: UIImage { get }
    var imagePickerCheckMark: UIImage { get }
    var imagePickerCheckMarkBackground: UIImage { get }
    var videoMessageInfoPlay: UIImage { get }
    var fullImageCloseButton: UIImage { get }
    var documentBubbleIcon: UIImage { get }
    var attachmentsPreviewItemRemove: UIImage { get }
    var replyPreviewRemove: UIImage { get }
    var otherMessengerSMS: UIImage { get }
    var otherMessengerEmail: UIImage { get }
    var otherMessengerTelegram: UIImage { get }
    var otherMessengerWhatsapp: UIImage { get }
}

extension ThemeImageSet {
    public var chatBackground: UIImage { UIImage.fromBundle(name: "chat_background") }
    public var statusSentUnreadMessage: UIImage { UIImage.fromBundle(name: "sent_unread") }
    public var statusSentReadMessage: UIImage { UIImage.fromBundle(name: "sent_read") }
    public var statusSendingMessage: UIImage { UIImage.fromBundle(name: "sending") }
    public var errorButton: UIImage { UIImage.fromBundle(name: "error_button") }
    public var slideToCancelIndicatorIcon: UIImage { UIImage.fromBundle(name: "slide_to_cancel_indicator") }
    public var sendMessageButton: UIImage { UIImage.fromBundle(name: "send_message") }
    public var attachPickersButton: UIImage { UIImage.fromBundle(name: "attach_picker") }
    public var voiceMessageButton: UIImage { UIImage.fromBundle(name: "send_voice") }
    public var scrollToBottomButton: UIImage { UIImage.fromBundle(name: "scroll_to_bottom") }
    public var voiceMessagePlayButton: UIImage { UIImage.fromBundle(name: "voicemessage_play") }
    public var voiceMessagePauseButton: UIImage { UIImage.fromBundle(name: "voicemessage_pause") }
    public var contactBubbleIcon: UIImage { UIImage.fromBundle(name: "contact") }
    public var locationPin: UIImage { UIImage.fromBundle(name: "location_pin") }
    public var locationInfoButton: UIImage { UIImage.fromBundle(name: "location_info") }
    public var locationPositionButton: UIImage { UIImage.fromBundle(name: "location_position") }
    public var imagePickerCheckMark: UIImage { UIImage.fromBundle(name: "check_image") }
    public var imagePickerCheckMarkBackground: UIImage { UIImage.fromBundle(name: "check_background") }
    public var videoMessageInfoPlay: UIImage { UIImage.fromBundle(name: "video_play") }
    public var fullImageCloseButton: UIImage { UIImage.fromBundle(name: "full_image_close_button") }
    public var documentBubbleIcon: UIImage { UIImage.fromBundle(name: "document") }
    public var replyIcon: UIImage { UIImage.fromBundle(name: "reply_image") }
    public var attachmentsPreviewItemRemove: UIImage { UIImage.fromBundle(name: "attachments_preview_item_remove") }
    public var replyPreviewRemove: UIImage { UIImage.fromBundle(name: "reply_preview_close") }
    public var otherMessengerSMS: UIImage { UIImage.fromBundle(name: "other_messenger_sms") }
    public var otherMessengerEmail: UIImage { UIImage.fromBundle(name: "other_messenger_email") }
    public var otherMessengerTelegram: UIImage { UIImage.fromBundle(name: "other_messenger_telegram") }
    public var otherMessengerWhatsapp: UIImage { UIImage.fromBundle(name: "other_messenger_whatsapp") }
}
