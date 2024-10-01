import Foundation
import CoreLocation
import AVKit
import Photos

protocol MessageInputPresenterProtocol: PickerDelegate {
    var isRecordingAllowed: Bool { get }
    var featureFlags: FeatureFlags { get set }
    var isVoiceButtonHidden: Bool { get set }

    var existingDraft: MessageDraftProviding? { get }

    func didLoad()

    func decideIfMaySendMessage(_ message: MessagePreview, _ asyncDecisionBlock: @escaping (Bool) -> Void)
    func willSendMessage(_ preview: MessagePreview?)
    func modifyTextBeforeSending(_ text: String) -> String

    func attachReply(_ reply: ReplyPreview)
    func sendText(_ text: String, guid: String?, completion: ((Bool) -> Void)?)
    func sendAttachments()

    func clearAllInput()
    func removeAttachment(attachmentID: String)
    func removeReply()

    @discardableResult
    func removeExistingDraft() -> MessageDraftProviding?

    func requestRecordPermission()
    func startVoiceMessageRecording()
    func stopVoiceMessageRecording()
    func cancelVoiceMessageRecording()

    func requestPresentation(controller: UIViewController)
    func updateTextViewEditingStatus(value: Bool)
    func didUpdateInput(text: String)
}

final class MessageInputPresenter: MessageInputPresenterProtocol {
    private weak var moduleDelegate: MessageInputDelegateProtocol?
    private let voiceMessageService: VoiceMessageServiceProtocol
    private let contactsService: ContactsServiceProtocol

    private var attachments: [ContentSender] = []
    private var reply: ReplyPreview?

    weak var viewController: MessageInputViewControllerProtocol?

    var isRecordingAllowed: Bool {
        self.voiceMessageService.isRecordingAllowed
    }

    var existingDraft: MessageDraftProviding? {
        guard self.featureFlags.contains(.canUseDrafts) else {
            return nil
        }
        return self.moduleDelegate?.retrieveExistingDraft()
    }

    private var originalFeatureFlags: FeatureFlags

    var featureFlags: FeatureFlags {
        didSet {
            self.viewController?.featureFlagsWereUpdated()
        }
    }

    var channelID: String

    init(
        channelID: String,
        moduleDelegate: MessageInputDelegateProtocol?,
        featureFlags: FeatureFlags,
        voiceMessageService: VoiceMessageServiceProtocol,
        contactsService: ContactsServiceProtocol
    ) {
        self.channelID = channelID
        self.moduleDelegate = moduleDelegate
        self.voiceMessageService = voiceMessageService
        self.contactsService = contactsService
        self.originalFeatureFlags = featureFlags
        self.featureFlags = featureFlags
    }

    func didLoad() {
        self.sendSharedFilesIfNeeded()
    }

    func sendContent(sender: ContentSender) {
        self.moduleDelegate?.willSendMessage(sender.messagePreview)
        self.moduleDelegate?.sendMessage(sender: sender, completion: nil)
    }

    func attachContent(senders: [ContentSender]) {
        defer {
            self.saveCurrentProgressAsDraft()
        }

        self.reply = nil
        self.attachments.append(contentsOf: senders)

        let attachmentsModels = self.attachments.compactMap { $0.attachmentPreview }
        self.viewController?.update(attachments: attachmentsModels)

        self.moduleDelegate?.didAttachmentsUpdate(.add, totalCount: attachmentsModels.count)
    }

    func willSendMessage(_ preview: MessagePreview?) {
        self.moduleDelegate?.willSendMessage(preview)
    }

    func decideIfMaySendMessage(_ message: MessagePreview, _ asyncDecisionBlock: @escaping (Bool) -> Void) {
        self.moduleDelegate?.decideIfMaySendMessage(message, asyncDecisionBlock)
    }

    func modifyTextBeforeSending(_ text: String) -> String {
        self.moduleDelegate?.modifyTextBeforeSending(text) ?? text
    }

    func sendText(_ text: String, guid: String?, completion: ((Bool) -> Void)?) {
        let text = self.moduleDelegate?.modifyTextBeforeSending(text) ?? text
        let sender = TextContentSender(guid: guid, text: text, reply: self.reply)
        let preview = sender.messagePreview

        self.decideIfMaySendMessage(preview) { [weak self] maySend in
            guard let self, maySend else {
                completion?(false)
                return
            }

            self.willSendMessage(preview)
            self.moduleDelegate?.sendMessage(sender: sender, completion: nil)

            self.removeReply()
            self.removeExistingDraft()

            self.saveCurrentProgressAsDraft(text: "")
            completion?(true)
        }
    }

    func sendAttachments() {
        defer {
            self.saveCurrentProgressAsDraft()
        }

        let attachments = self.attachments
        attachments.forEach { attachment in
            let preview = attachment.messagePreview

            self.decideIfMaySendMessage(preview) { [weak self] maySend in
                guard let self, maySend else { return }

                self.willSendMessage(preview)
                self.sendContent(sender: attachment)

                self.attachments = self.attachments.filter {
                    $0.messageGUID != attachment.messageGUID
                }

                let attachmentPreviews = self.attachments.compactMap(\.attachmentPreview)
                self.viewController?.update(attachments: attachmentPreviews)
                self.moduleDelegate?.didAttachmentsUpdate(.remove, totalCount: attachmentPreviews.count)
            }
        }
    }

    func removeAttachment(attachmentID: String) {
        guard let attachmentIndex = self.attachments.firstIndex(where: { $0.messageGUID == attachmentID }) else {
            return
        }

        self.attachments.remove(at: attachmentIndex)

        let attachmentsModels = self.attachments.compactMap { $0.attachmentPreview }
        self.viewController?.update(attachments: attachmentsModels)
        self.moduleDelegate?.didAttachmentsUpdate(.remove, totalCount: attachmentsModels.count)

        self.saveCurrentProgressAsDraft()
    }

    func clearAllInput() {
        self.removeExistingDraft()
        self.attachments.removeAll()
        self.saveCurrentProgressAsDraft(text: "")
    }

    func attachReply(_ reply: ReplyPreview) {
        self.attachments.removeAll()
        self.viewController?.update(attachments: [])

        self.reply = reply
        self.viewController?.update(reply: reply)
    }

    func removeReply() {
        self.reply = nil
        self.viewController?.update(reply: nil)
    }

    func requestRecordPermission() {
        self.voiceMessageService.requestRecordPermission { _ in
            // TODO: - Add alert
        }
    }

    func startVoiceMessageRecording() {
        self.voiceMessageService.startRecording()
        self.moduleDelegate?.didVoiceMessageStatusUpdate(with: .start)
    }

    func stopVoiceMessageRecording() {
        self.voiceMessageService.onRecordingCompletion = { [weak self] data in
            data.flatMap {
                let sender = VoiceMessageContentSender(messageContent: $0)
                let preview = sender.messagePreview

                self?.moduleDelegate?.decideIfMaySendMessage(preview) { maySend in
                    if maySend {
                        self?.removeReply()
                        self?.moduleDelegate?.willSendMessage(preview)
                        self?.moduleDelegate?.sendMessage(sender: sender, completion: nil)
                    }
                }
            }
        }

        self.voiceMessageService.stopRecording()
        self.moduleDelegate?.didVoiceMessageStatusUpdate(with: .stop)
    }

    func cancelVoiceMessageRecording() {
        self.voiceMessageService.onRecordingCompletion = nil
        self.voiceMessageService.stopRecording()
        self.moduleDelegate?.didVoiceMessageStatusUpdate(with: .cancel)
    }

    func requestPresentation(controller: UIViewController) {
        self.moduleDelegate?.present(controller: controller)
    }

    func updateTextViewEditingStatus(value: Bool) {
        self.moduleDelegate?.didTextViewEditingStatusUpdate(with: value)
    }

    func didUpdateInput(text: String) {
        self.saveCurrentProgressAsDraft(text: text)
    }
    
    func subscribeToNotifications() {
        Notification.onReceive(UIApplication.didBecomeActiveNotification) { [weak self] _ in
            self?.sendSharedFilesIfNeeded()
        }
    }

    var isVoiceButtonHidden: Bool {
        get {
            !self.featureFlags.contains(.canSendVoiceMessage)
        }
        set {
            var featureFlags = self.originalFeatureFlags
            if newValue {
                featureFlags = featureFlags.subtracting(.canSendVoiceMessage)
            }
            self.featureFlags = featureFlags
        }
    }

    @discardableResult
    func removeExistingDraft() -> MessageDraftProviding? {
        let draft = self.existingDraft
        self.moduleDelegate?.removeExistingDraft()
        return draft
    }

    // MARK: - Private
    
    @objc
    private func sendSharedFilesIfNeeded() {
        guard self.channelID.lowercased().hasPrefix("n") else {
            return
        }

        let groupName = Configuration.sharingGroupName
        let fileManager = FileManager.default
        let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupName)
        var content: [URL] = []
        do {
            if let container = container {
                let directoryPath  = container.appendingPathComponent("files")
                content = try FileManager.default.contentsOfDirectory(
                    at: directoryPath,
                    includingPropertiesForKeys: nil
                )
            }
        } catch let error as NSError {
            log(sender: self, error.description)
        }
        self.sendShared(urls: content)
    }
    
    private func saveCurrentProgressAsDraft(text: String? = nil) {
        let existingDraft = self.existingDraft
        let existingDraftText = text ?? existingDraft?.text ?? ""
        let guid = existingDraft?.guid ?? UUID().uuidString
        self.moduleDelegate?.saveDraft(
            messageGUID: guid,
            messageStatus: .draft,
            text: existingDraftText,
            attachments: self.attachments
        )
    }
    
    private func sendShared(urls: [URL]) {
        if urls.isEmpty {
            return
        }
        urls.forEach { item in
            if ["JPG", "JPE", "BMP", "GIF", "PNG"].contains(item.pathExtension.uppercased()) {
                self.sendSharedImage(url: item)
            } else if ["MOV" , "MP4", "AVI", "WMV"].contains(item.pathExtension.uppercased()) {
                self.sendSharedVideo(url: item)
            } else if item.lastPathComponent == "incomeText.txt" {
                self.sendSharedText(url: item)
            } else {
                self.sendSharedFile(url: item)
            }
        }
    }
    
    private func cleanSharingFile(url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "error": error
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)
            
            log(sender: self, error)
        }
    }
    
    private func sendSharedImage(url: URL) {
        guard let image = UIImage(contentsOfFile: url.path) else { return }
        let imageAttach = ImageContentSender(
            image: image,
            name: url.lastPathComponent,
            messageContent: image.pngData() ?? Data()
        )
        DispatchQueue.main.async {
            self.attachContent(senders: [imageAttach])
            self.cleanSharingFile(url: url)
        }
    }
    
    private func sendSharedVideo(url: URL) {
        let urlAsset = AVURLAsset(url: url)
        let data = try? Data(contentsOf: urlAsset.url)
        urlAsset.generateThumbnail { image in
            let videoAttach = VideoContentSender(
                previewImage: image ?? UIImage(),
                name: url.lastPathComponent,
                messageContent: data ?? Data(),
                duration: urlAsset.duration.seconds
            )
            DispatchQueue.main.async {
                self.attachContent(senders: [videoAttach])
                self.cleanSharingFile(url: url)
            }
        }
    }
    
    private func sendSharedFile(url: URL) {
        let docAttach = DocumentContentSender(sourceContentURL: url)
        self.sendContent(sender: docAttach)
        DispatchQueue.main.async {
            self.cleanSharingFile(url: url)
        }
    }
    
    private func sendSharedText(url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            DispatchQueue.main.async {
                self.viewController?.set(message: text)
                self.cleanSharingFile(url: url)
            }
        } catch {
            let userInfo: [String: Any] = [
                "sender": "\(type(of: self)) \(#function)",
                "error": error,
                "details": "sendSharedText"
            ]

            NotificationCenter.default.post(.chatSDKDidEncounterError, userInfo: userInfo)

            log(sender: self, error)
        }
    }
}
