import UIKit

public protocol ChatProtocol: AnyObject {
    var isWholeInputControlHidden: Bool { get set }
    var isVoiceButtonHidden: Bool { get set }

    /// Add a new bottom additional view
    func addBottomView(_ view: UIView)
    
    /// Send a message to the channel
    func sendMessage(sender: ContentSender)

    func sendMessage(text: String, completion: ((Bool) -> Void)?)

    /// Retry failed message sending
    func retryFailedMessage(with id: String)

    /// Attach input accessory to sender module
    func setInputAccessory(_ view: UIView?)

    func addInputDecoration(_ view: UIView)

    /// Shows the keyboard to invite user to start chatting immediately
    func showKeyboardWhenAppeared()

    func sendDraftWhenAppeared()

    /// Attach overlay on top of chat module
    func setOverlay(_ view: UIView)

    /// Update input
    func updateInput(with draft: MessageDraftProviding?)

    /// Remove draft
    func removeExistingDraft() -> MessageDraftProviding?

    /// Self-associated view controller
    var viewController: UIViewController { get }
}

public protocol ChatDelegateProtocol: AnyObject {
    /// Request phone call
    func requestPhoneCall(number: String)

    /// Request modal controller presentation
    func requestPresentation(for controller: UIViewController, completion: (() -> Void)?)

    /// Report about text message view editing status update
    func didTextViewEditingStatusUpdate(with value: Bool)

    /// Report about message state
    func didMessageSendingStatusUpdate(with status: MessageSendingStatus, preview: MessagePreview)

    /// Report about close channel module
    func didChatControllerStatusUpdate(with status: ChatControllerStatus)

    /// Report about attachments area status
    func didAttachmentsUpdate(_ update: AttachmentsUpdate, totalCount: Int)

    /// Report about voice message status
    func didVoiceMessageStatusUpdate(with status: VoiceMessageStatus)

    func willSendMessage(_ preview: MessagePreview?)

    func modifyTextBeforeSending(_ text: String) -> String

    func decideIfMaySendMessage(_ message: MessagePreview, _ asyncDecisionBlock: @escaping (Bool) -> Void)

    func didLoadInitialMessages()

    func didUpdateDraft(event: ChatEditingEvent)

    /// Show bottom safe area view
    var shouldShowSafeAreaView: Bool { get }
}

/// Current chat controller life state
public enum ChatControllerStatus {
    case load
    case unload
}

/// Current message sending status
public enum MessageSendingStatus {
    case success
    case error
    case inProgress
}

/// Current attachments area status
public enum AttachmentsUpdate {
    case add
    case remove
}

/// Current voice message status
public enum VoiceMessageStatus {
    case start
    case stop
    case cancel
}

struct ChatAssembly {
    // swiftlint:disable:next function_parameter_count
    static func make(
        channelID: String,
        clientID: String,
        featureFlags: FeatureFlags,
        moduleDelegate: ChatDelegateProtocol?,
        messageService: MessageServiceProtocol,
        contentRendererFactory: ContentRendererFactory,
        pickerModuleFactory: PickerModuleFactory,
        voiceMessageService: VoiceMessageServiceProtocol,
        fileService: FileServiceProtocol,
        cacheService: CacheServiceProtocol,
        contactsService: ContactsServiceProtocol,
        locationService: LocationServiceProtocol,
        messageTypesToIgnore: [MessageType],
        preinstalledText: String? = nil,
        messageGuidToOpen: String? = nil
    ) -> ChatViewController {
        let chatPresenter = ChatPresenter(
            clientID: clientID,
            channelID: channelID,
            featureFlags: featureFlags,
            messageService: messageService,
            fileService: fileService,
            cacheService: cacheService,
            locationService: locationService,
            voiceMessageService: voiceMessageService,
            contentRendererFactory: contentRendererFactory,
            messageTypesToIgnore: messageTypesToIgnore,
            preinstalledText: preinstalledText
        )
        chatPresenter.moduleDelegate = moduleDelegate

        let messageInputViewController = MessageInputAssembly.make(
            channelID: channelID,
            output: chatPresenter,
            featureFlags: featureFlags,
            pickerModuleFactory: pickerModuleFactory,
            voiceMessageService: voiceMessageService,
            contactsService: contactsService,
            locationService: locationService
        )
        chatPresenter.messageInputViewController = messageInputViewController

        let messagesListViewController = MessagesListAssembly.make(
            contentRenderers: contentRendererFactory.presenters,
            messageGuidToOpen: messageGuidToOpen,
            delegate: chatPresenter
        )
        chatPresenter.messagesListViewController = messagesListViewController

        let chatViewController = ChatViewController(
            messagesListViewController: messagesListViewController,
            messageInputViewController: messageInputViewController,
            presenter: chatPresenter
        )

        return chatViewController
    }
}

public extension Notification.Name {
    static let chatNetworkErrorNotification = Notification.Name("chatNetworkErrorNotification")
}
