import UIKit

/// Dependencies for pickers (location, voice message, audio / video, ...)
struct MessageInputPickerDependencies {
    let voiceMessageService: VoiceMessageServiceProtocol
    let locationService: LocationServiceProtocol
}

/// Reply preview model
public struct ReplyPreview: Codable {
    let guid: String
    let reply: String
    let sender: String
}

public protocol MessageInput: AnyObject {
    var isWholeInputControlHidden: Bool { get set }
    var isVoiceButtonHidden: Bool { get set }
    func attach(reply: ReplyPreview)
    func showKeyboardWhenAppeared()
    func sendDraftWhenAppeared()
    func setInputAccessory(_ view: UIView?)
    func addInputDecoration(_ view: UIView)
    func removeExistingDraft() -> MessageDraftProviding?
    func set(message: String)
    var viewController: UIViewController { get }
}

public protocol MessageDraftProviding {
    var guid: String { get }
    var text: String { get }
    var attachments: [ContentSender] { get }
}

public protocol MessageInputDelegateProtocol: AnyObject {
    func decideIfMaySendMessage(_ message: MessagePreview, _ asyncDecisionBlock: @escaping (Bool) -> Void)
    func modifyTextBeforeSending(_ text: String) -> String
    func sendMessage(sender: ContentSender, completion: ((Bool) -> Void)?)
    func present(controller: UIViewController)
    func willSendMessage(_ preview: MessagePreview?)
    func didTextViewEditingStatusUpdate(with value: Bool)
    func didAttachmentsUpdate(_ update: AttachmentsUpdate, totalCount: Int)
    func didVoiceMessageStatusUpdate(with status: VoiceMessageStatus)
    func retrieveExistingDraft() -> MessageDraftProviding?
    func removeExistingDraft()
    func saveDraft(
        messageGUID: String,
        messageStatus: MessageStatus,
        text: String,
        attachments: [ContentSender]
    )
}

struct MessageInputAssembly {

    // swiftlint:disable:next function_parameter_count
    static func make(
        channelID: String,
        output: MessageInputDelegateProtocol?,
        featureFlags: FeatureFlags,
        pickerModuleFactory: PickerModuleFactory,
        voiceMessageService: VoiceMessageServiceProtocol,
        contactsService: ContactsServiceProtocol,
        locationService: LocationServiceProtocol
    ) -> MessageInputViewController {
        let presenter = MessageInputPresenter(
            channelID: channelID,
            moduleDelegate: output,
            featureFlags: featureFlags,
            voiceMessageService: voiceMessageService,
            contactsService: contactsService
        )

        let pickerDependencies = MessageInputPickerDependencies(
            voiceMessageService: voiceMessageService,
            locationService: locationService
        )

        let viewController = MessageInputViewController(
            presenter: presenter,
            pickerDependencies: pickerDependencies,
            pickerModuleFactory: pickerModuleFactory
        )

        presenter.viewController = viewController
        return viewController
    }
}
