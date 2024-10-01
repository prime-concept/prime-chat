import UIKit

/// Chat SDK configuration object
public struct Configuration {
    /// Chat server URL
    public var chatBaseURL: URL
    /// File storage URL
    public var storageBaseURL: URL
    /// Additional content presenters
    public var contentRenderers: [ContentRenderer.Type]
    /// Additional content senders
    public var contentSenders: [ContentSender.Type]
    /// Initial theme
    public var initialTheme: Theme
    /// Additional pickers
    public var pickerModules: [(MessageContent.Type, PickerModule.Type)]
    /// Feature flags
    public var featureFlags: FeatureFlags
    /// Client application ID
    public var clientAppID: String?
    /// Enable logging
    public var shouldEnableLogging: Bool
    
    public static var sharingGroupName: String = "REPLACE_ME"
    public static var phoneNumberToSendSMSIfNoInternet: String?
    public static var urlOpeningHandler: ((URL) -> Bool)?

    public static var showLoadingIndicator: ((UIViewController?) -> Void)?
    public static var hideLoadingIndicator: ((UIViewController?) -> Void)?

    public init(
        chatBaseURL: URL,
        storageBaseURL: URL,
        contentRenderers: [ContentRenderer.Type] = [],
        contentSenders: [ContentSender.Type] = [],
        initialTheme: Theme = Theme.default,
        pickerModules: [(MessageContent.Type, PickerModule.Type)] = [],
        featureFlags: FeatureFlags = FeatureFlags.all(),
        clientAppID: String? = nil,
        shouldEnableLogging: Bool = false
    ) {
        self.chatBaseURL = chatBaseURL
        self.storageBaseURL = storageBaseURL
        self.contentRenderers = contentRenderers
        self.contentSenders = contentSenders
        self.initialTheme = initialTheme
        self.pickerModules = pickerModules
        self.featureFlags = featureFlags
        self.clientAppID = clientAppID
        self.shouldEnableLogging = shouldEnableLogging
    }

    // MARK: - Feature flags

    public struct FeatureFlags: OptionSet {
        private static let all: Self = [
            .canSendContactMessage,
            .canSendLocationMessage,
            .canSendImageAndVideoMessage,
            .showSenderShadow,
            .canSendVoiceMessage,
            .canSendFileMessage,
            .canUseDrafts,
            .canReadReceipts
        ]

        public let rawValue: Int

        /// Possibility to send messages with vcf
        public static let canSendContactMessage = FeatureFlags(rawValue: 1 << 0)
        /// Possibility to send messages with location
        public static let canSendLocationMessage = FeatureFlags(rawValue: 1 << 1)
        /// Possibility to send messages with image / videos
        public static let canSendImageAndVideoMessage = FeatureFlags(rawValue: 1 << 2)
        /// Show sender shadow
        public static let showSenderShadow = FeatureFlags(rawValue: 1 << 3)
        /// Possibility to send voice messages
        public static let canSendVoiceMessage = FeatureFlags(rawValue: 1 << 4)
        /// Possibility to send files
        public static let canSendFileMessage = FeatureFlags(rawValue: 1 << 5)
        /// Possibility to use drafts
        public static let canUseDrafts = FeatureFlags(rawValue: 1 << 6)
        /// Possibility to activate read receipts
        public static let canReadReceipts = FeatureFlags(rawValue: 1 << 7)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static func all(except flags: Self = .init()) -> Self {
            return Self.all.symmetricDifference(flags)
        }
    }
}
