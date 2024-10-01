import UIKit
import MessageUI
import ContactsUI
import CoreLocation

public extension Notification.Name {
    /// Provide here a [MessageType] by "attachmentTypes" key to indicate 
    /// which attachments should be supported by the picker.
    static let messageInputAllowedAttachmentTypes = Notification.Name("messageInputAllowedAttachmentTypes")
    static let messageInputShouldHideKeyboard = Notification.Name("messageInputShouldHideKeyboard")
    static let messageInputShouldShowKeyboard = Notification.Name("messageInputShouldShowKeyboard")
    static let messageInputShouldResaveRestoredDraft = Notification.Name("messageInputShouldResaveRestoredDraft")
}

protocol MessageInputViewControllerProtocol: UIViewController, MessageInput {
    // Sets inputAccessoryView for current UITextView
    func setInputAccessory(_ view: UIView?)

    // Adds any additional views atop current input view
    func addInputDecoration(_ view: UIView)

    func update(attachments: [AttachmentPreview])
    func update(reply: ReplyPreview?)
    func set(message: String)
    func featureFlagsWereUpdated()
}

// swiftlint:disable:next type_body_length
final class MessageInputViewController: UIViewController {
    private enum Appearance {
        static let shadowHeight: CGFloat = 1.0 / UIScreen.main.scale
        static let height: CGFloat = 44.0
        static let buttonSize = CGSize(width: 44, height: 44)

        static let placeholderFont = ThemeProvider.current.fontProvider.senderPlaceholder

        static let badgeSize = CGSize(width: 18, height: 18)
        static let badgeFont = ThemeProvider.current.fontProvider.senderBadge
        static let recordingButtonLeft: CGFloat = 77
        static let attachmentsPreviewHeight: CGFloat = 90 + Self.shadowHeight
        static let replyMessageHeight: CGFloat = 50 + Self.shadowHeight
    }

    private let presenter: MessageInputPresenterProtocol

    private var pickerAlertControllerTintColor: UIColor? = Theme.default.palette.pickerAlertControllerTint

    private var attachmentTypes: [MessageType] = MessageType.allCases
    private var shouldResaveDraftAfterRestore: Bool = true

    private lazy var sendButtonDebouncer = Debouncer(timeout: 0.5) { [weak self] in
        self?.sendButtonClicked()
    }

    let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setEventHandler(for: .touchUpInside) { [weak self] in
            self?.sendButtonDebouncer.reset()
        }
        return button
    }()

    private lazy var moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.moreButtonClicked), for: .touchUpInside)
        return button
    }()

    private lazy var voiceButton: MessageRecordingButton = {
        let button = MessageRecordingButton(type: .system)
        button.onShouldHandleTouch = { [weak self] in
            let result = self?.presenter.isRecordingAllowed ?? false
            if !result {
                self?.presenter.requestRecordPermission()
            }
            return result
        }
        button.onRecordingStart = { [weak self] in
            UIApplication.shared.isIdleTimerDisabled = true
            self?.startTimer()
            self?.addRecordingDecoration()
            self?.presenter.startVoiceMessageRecording()
        }
        button.onRecordingEnd = { [weak self] in
            self?.stopTimer()
            self?.removeRecordingDecoration()
            self?.presenter.stopVoiceMessageRecording()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        button.onRecordingCancel = { [weak self] in
            self?.stopTimer()
            self?.removeRecordingDecoration()
            self?.presenter.cancelVoiceMessageRecording()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        return button
    }()

    private lazy var badgeLabel: AttachmentBadgeView = {
        let label = AttachmentBadgeView(size: Appearance.badgeSize)
        label.isHidden = true
        label.badgeFont = Appearance.badgeFont.font
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.moreButtonClicked)))
        return label
    }()

    private lazy var inputTextView: MessageGrowingTextView = {
        let textField = MessageGrowingTextView()
        textField.placeholder = "message".localized
        textField.font = Appearance.placeholderFont.font
        textField.lineHeight = Appearance.placeholderFont.lineHeight
        textField.baselineOffset = Appearance.placeholderFont.baselineOffset
        textField.minHeight = Appearance.height
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .sentences

        textField.onTextChange = { [weak self] text in
            self?.showAppropriateSendButton()
            self?.presenter.didUpdateInput(text: text)
        }

        textField.onHeightChange = { [weak self] height in
            self?.heightConstraint?.constant = height
        }

        textField.onTextBeginEditing = { [weak presenter] in
            presenter?.updateTextViewEditingStatus(value: true)
        }

        textField.onTextEndEditing = { [weak presenter] in
            presenter?.updateTextViewEditingStatus(value: false)
        }

        textField.delegate = self

        return textField
    }()

    private lazy var recordingView: MessageRecordingView = {
        let view = MessageRecordingView()
        view.alpha = 0
        return view
    }()

    private lazy var attachmentsPreviewView: AttachmentsPreviewView = {
        let view = AttachmentsPreviewView(frame: .zero, shouldHideShadow: self.shouldHideShadow)
        view.onRemoveAttachment = { [weak self] attachmentID in
            self?.presenter.removeAttachment(attachmentID: attachmentID)
        }

        return view
    }()

    private lazy var replyMessageView: ReplyPreviewView = {
        let view = ReplyPreviewView()
        view.onCloseTap = { [weak self] in
            self?.presenter.removeReply()
        }
        return view
    }()

    private lazy var shadowView = UIView()

    private var heightConstraint: NSLayoutConstraint?

    private let pickerDependencies: MessageInputPickerDependencies
    private let pickerModuleFactory: PickerModuleFactory
    private var themeProvider: ThemeProvider?
    private var recordingTimer: Timer?
    private var lastRecordingStartDate: Date?
    private var shouldShowKeyboardWhenAppeared = false
    private var shouldSendDraftWhenAppeared = false

    private var shouldHideShadow: Bool {
        self.presenter.featureFlags.contains(.showSenderShadow) == false
    }

    private var shouldHideVoiceButton: Bool {
        self.presenter.featureFlags.contains(.canSendVoiceMessage) == false
    }

    private var someAttachmentsExist = false

    init(
        presenter: MessageInputPresenterProtocol,
        pickerDependencies: MessageInputPickerDependencies,
        pickerModuleFactory: PickerModuleFactory
    ) {
        self.presenter = presenter
        self.pickerDependencies = pickerDependencies
        self.pickerModuleFactory = pickerModuleFactory

        super.init(nibName: nil, bundle: nil)
        
        self.subscribeToNotifications()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // http://stackoverflow.com/questions/24596031/uiviewcontroller-with-inputaccessoryview-is-not-deallocated
    /*
     Instead of implementing inputAccessoryView on the ViewController,
     we create a custom UIView and implement inputAccessoryView on the view
     to prevent retain cycle, that can only occurs when you're pushing/popping off
     of a UINavigationController stack, not via modal popup.
    */
    override func loadView() {
        self.view = MessageInputView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.themeProvider = ThemeProvider(themeUpdatable: self)
        self.setupSubviews()
        self.presenter.didLoad()
        self.restoreDraft()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.shouldShowKeyboardWhenAppeared {
            self.inputTextView.becomeFirstResponder()
            self.shouldShowKeyboardWhenAppeared = false
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.sendDraftWhenAppearedIfNeeded()
    }

    private func sendDraftWhenAppearedIfNeeded() {
        guard self.shouldSendDraftWhenAppeared else {
            return
        }

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.sendDraft()
            self.presenter.clearAllInput()
        }
        CATransaction.commit()
        self.shouldSendDraftWhenAppeared = false
    }

    // MARK: - Private

    private func subscribeToNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restrictToAttachments(in:)),
            name: .messageInputAllowedAttachmentTypes,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideKeyboard(_:)),
            name: .messageInputShouldHideKeyboard,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showKeyboard(_:)),
            name: .messageInputShouldShowKeyboard,
            object: nil
        )
    }

    @objc
    private func restrictToAttachments(in notification: Notification) {
        let messageTypes = notification.userInfo?["attachmentTypes"] as? [MessageType]
        self.attachmentTypes = messageTypes ?? MessageType.allCases
    }

    private func showAppropriateSendButton() {
        if self.someAttachmentsExist {
            self.showSendButton()
            return
        }
        
        if self.inputTextView.text.isEmpty && !self.shouldHideVoiceButton {
            self.showVoiceMessageButton()
            return
        }
        
        self.showSendButton()
    }

    private func showSendButton() {
        self.voiceButton.superview?.isHidden = true
        self.sendButton.superview?.isHidden = false
    }

    private func showVoiceMessageButton() {
        self.voiceButton.superview?.isHidden = false
        self.sendButton.superview?.isHidden = true
    }

    @objc
    // swiftlint:disable:next cyclomatic_complexity
    private func moreButtonClicked() {
        self.inputTextView.resignFirstResponder()

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceView = self.moreButton

        let flags = self.presenter.featureFlags
        let modules = self.pickerModuleFactory.allModules()
            .filter { picker in
                if picker.hasResult(oneOf: [ContactContent.self]) {
                    if !flags.contains(.canSendContactMessage) || !self.attachmentTypes.contains(.contact) {
                        return false
                    }
                }

                if picker.hasResult(oneOf: [LocationContent.self]) {
                    if !flags.contains(.canSendLocationMessage) || !self.attachmentTypes.contains(.location) {
                        return false
                    }
                }

                if picker.hasResult(oneOf: [DocumentContent.self]) {
                    if !flags.contains(.canSendFileMessage) || !self.attachmentTypes.contains(.doc) {
                        return false
                    }
                }

                if picker.hasResult(oneOf: [ImageContent.self, VideoContent.self]) {
                    let imageVideoEnabled = self.attachmentTypes.contains(.image)
                    && self.attachmentTypes.contains(.video)
                    if !flags.contains(.canSendImageAndVideoMessage) || !imageVideoEnabled {
                        return false
                    }
                }

                return true
            }

        for pickerModule in modules {
            guard let listItem = pickerModule.listItem else {
                continue
            }

            let action = UIAlertAction(title: listItem.title, style: .default) { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }

                let module = pickerModule.init(
                    dependencies: PickerModuleDependencies(
                        locationService: strongSelf.pickerDependencies.locationService
                    )
                )
                module.pickerDelegate = strongSelf.presenter

                if pickerModule.shouldPresentWithNavigationController {
                    let pickerController = StylizedNavigationContoller(rootViewController: module.viewController)
                    pickerController.modalPresentationStyle = pickerModule.modalPresentationStyle
                    strongSelf.presenter.requestPresentation(controller: pickerController)
                } else {
                    let destination = module.viewController
                    destination.modalPresentationStyle = pickerModule.modalPresentationStyle
                    strongSelf.presenter.requestPresentation(controller: destination)
                }
            }
            alertController.addAction(action)
        }

        let closeAction = UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil)
        alertController.addAction(closeAction)
        if let tintColor = self.pickerAlertControllerTintColor {
//            alertController.view.tintColor = tintColor
        }

        self.topmostPresentedOrSelf.present(alertController, animated: true, completion: nil)
    }

    @objc
    private func sendButtonClicked() {
        defer {
            self.showAppropriateSendButton()
        }

        guard NetworkMonitor.shared.isConnected else {
            self.promptSMS(self.inputTextView.text)
            return
        }

        self.presenter.decideIfMaySendMessage(.outcomeStub) { [weak self] mayProceed in
            guard let self, mayProceed else {
                return
            }

            self.sendText()
            delay(0.1) {
                self.sendAttachments()
            }
        }
    }

    private func sendText() {
        let text = self.inputTextView.text

        guard let text, !text.isEmpty else {
            return
        }

        var guid: String?
        if let draft = self.presenter.existingDraft, !draft.text.isEmpty {
            guid = draft.guid
        }

        self.presenter.sendText(text, guid: guid) { [weak self] success in
            if success {
                self?.inputTextView.text = nil
            }
        }
    }

    private func sendAttachments() {
        self.presenter.sendAttachments()
    }
    
    private func restoreDraft() {
        guard let existingDraftProvider = self.presenter.existingDraft else {
            return
        }

        self.presenter.clearAllInput()
        
        self.inputTextView.setPreinstalledText(existingDraftProvider.text)
        self.presenter.attachContent(senders: existingDraftProvider.attachments)
    }

    private func sendDraft() {
        guard let existingDraft = self.presenter.existingDraft else {
            return
        }

        existingDraft.attachments.forEach { self.presenter.sendContent(sender: $0) }
        if existingDraft.text.isEmpty {
            return
        }

        self.presenter.sendText(existingDraft.text, guid: existingDraft.guid) { [weak self] success in
            if success {
                self?.inputTextView.text = nil
            }
        }
    }

    private func setupSubviews() {
        guard let view = self.view, let layoutProvider = self.themeProvider?.current.layoutProvider else {
            return
        }

        func wrapButton(_ view: UIView) -> UIView {
            let wrapper = UIView()

            wrapper.addSubview(view)

            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalToConstant: Appearance.buttonSize.width).isActive = true
            view.heightAnchor.constraint(equalToConstant: Appearance.buttonSize.height).isActive = true

            view.topAnchor.constraint(greaterThanOrEqualTo: wrapper.topAnchor, constant: 0).isActive = true
            view.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 0).isActive = true
            view.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: 0).isActive = true
            view.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: 0).isActive = true

            return wrapper
        }

        // Vertical StackView
        view.addSubview(self.verticalStackView)
        self.verticalStackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.verticalStackView.leadingAnchor.constraint(
            equalTo: view.leadingAnchor,
            constant: layoutProvider.messageInputHorizontalInset
        ).isActive = true
        self.verticalStackView.trailingAnchor.constraint(
            equalTo: view.trailingAnchor,
            constant: -layoutProvider.messageInputHorizontalInset
        ).isActive = true
        self.verticalStackView.bottomAnchor.constraint( equalTo: view.bottomAnchor).isActive = true

        // Horizontal StackView

        let horizontalStackView = UIStackView()
        horizontalStackView.axis = .horizontal

        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = horizontalStackView.heightAnchor.constraint(equalToConstant: Appearance.height)
        heightConstraint.isActive = true
        self.heightConstraint = heightConstraint

        // MoreButton

        let moreButton = wrapButton(self.moreButton)

        moreButton.addSubview(self.badgeLabel)
        self.badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.badgeLabel.topAnchor.constraint(equalTo: moreButton.topAnchor, constant: 6).isActive = true
        self.badgeLabel.trailingAnchor.constraint(equalTo: moreButton.trailingAnchor, constant: -4).isActive = true

        horizontalStackView.addArrangedSubview(wrapButton(moreButton))

        // InputTextView

        horizontalStackView.addArrangedSubview(self.inputTextView)

        // SendButton

        horizontalStackView.addArrangedSubview(wrapButton(self.sendButton))
        self.sendButton.superview?.isHidden = true

        // VoiceButton

        if self.shouldHideVoiceButton == false {
            horizontalStackView.addArrangedSubview(wrapButton(self.voiceButton))
        }

        // AttachmentsPreviewView

        let attachmentsPreviewView = self.attachmentsPreviewView

        attachmentsPreviewView.translatesAutoresizingMaskIntoConstraints = false
        attachmentsPreviewView.heightAnchor
            .constraint(equalToConstant: Appearance.attachmentsPreviewHeight).isActive = true
        attachmentsPreviewView.isHidden = true

        // Reply view

        let replyView = self.replyMessageView

        replyView.translatesAutoresizingMaskIntoConstraints = false
        replyView.heightAnchor.constraint(equalToConstant: Appearance.replyMessageHeight).isActive = true
        replyView.isHidden = true

        // ShadowView

        let shadowView = self.shadowView

        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.heightAnchor.constraint(equalToConstant: Appearance.shadowHeight).isActive = true
        shadowView.isHidden = self.shouldHideShadow

        // Arrange views in correct order
        self.verticalStackView.addArrangedSubview(attachmentsPreviewView)
        self.verticalStackView.addArrangedSubview(replyView)
        self.verticalStackView.addArrangedSubview(shadowView)
        self.verticalStackView.addArrangedSubview(horizontalStackView)

        // RecordingView

        let recordingView = self.recordingView

        horizontalStackView.addSubview(recordingView)
        recordingView.translatesAutoresizingMaskIntoConstraints = false
        recordingView.leadingAnchor.constraint(equalTo: horizontalStackView.leadingAnchor).isActive = true
        recordingView.trailingAnchor
            .constraint(equalTo: horizontalStackView.trailingAnchor, constant: -Appearance.recordingButtonLeft)
            .isActive = true
        recordingView.bottomAnchor.constraint(equalTo: horizontalStackView.bottomAnchor).isActive = true
        recordingView.heightAnchor.constraint(equalTo: horizontalStackView.heightAnchor).isActive = true
    }

    private func addRecordingDecoration() {
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                self.recordingView.alpha = 1
            },
            completion: nil
        )
    }

    private func removeRecordingDecoration() {
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 1,
            options: [],
            animations: {
                self.recordingView.alpha = 0
            },
            completion: nil
        )
    }

    private func startTimer() {
        self.lastRecordingStartDate = Date()
        self.recordingTimer = Timer.scheduledTimer(
            timeInterval: 0.05,
            target: self,
            selector: #selector(self.updateRecordingTime),
            userInfo: nil,
            repeats: true
        )
    }

    private func stopTimer() {
        self.recordingTimer?.invalidate()
        self.recordingTimer = nil
        self.recordingView.update(time: nil)
    }

    @objc
    private func updateRecordingTime() {
        guard let lastRecordingStartDate = self.lastRecordingStartDate else {
            return
        }

        let interval = Date().timeIntervalSince(lastRecordingStartDate)
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        let miliseconds = Int((interval * 100).truncatingRemainder(dividingBy: 100))

        self.recordingView.update(time: String(format: "%d:%02d:%.02d", minutes, seconds, miliseconds))
    }
}

extension MessageInputViewController: ThemeUpdatable {
    func update(with theme: Theme) {
        self.sendButton.setImage(theme.imageSet.sendMessageButton.withRenderingMode(.alwaysTemplate), for: .normal)
        self.moreButton.setImage(theme.imageSet.attachPickersButton.withRenderingMode(.alwaysTemplate), for: .normal)
        self.voiceButton.setImage(theme.imageSet.voiceMessageButton.withRenderingMode(.alwaysTemplate), for: .normal)

        self.sendButton.tintColor = theme.palette.senderButton
        self.moreButton.tintColor = theme.palette.senderButton
        self.voiceButton.tintColor = theme.palette.senderButton

        self.inputTextView.backgroundColor = theme.palette.senderBackground
        self.inputTextView.placeholderColor = theme.palette.senderPlaceholderColor
        self.inputTextView.textColor = theme.palette.senderTextColor

        self.shadowView.backgroundColor = theme.palette.senderBorderShadow
        self.view.backgroundColor = theme.palette.senderBackground

        self.pickerAlertControllerTintColor = theme.palette.pickerAlertControllerTint
    }
}

extension MessageInputViewController: MessageInputViewControllerProtocol {
    @objc
    func hideKeyboard(_ notification: Notification) {
        guard (notification.userInfo?["animated"] as? Bool) == true else {
            UIView.performWithoutAnimation {
                self.inputTextView.resignFirstResponder()
            }
            return
        }
        self.inputTextView.resignFirstResponder()
    }

    @objc
    func showKeyboard(_ notification: Notification) {
        guard (notification.userInfo?["animated"] as? Bool) == true else {
            UIView.performWithoutAnimation {
                self.inputTextView.becomeFirstResponder()
            }
            return
        }
        self.inputTextView.becomeFirstResponder()
    }

    func update(attachments: [AttachmentPreview]) {
        self.attachmentsPreviewView.update(with: attachments)

        self.attachmentsPreviewView.isHidden = attachments.isEmpty
        if self.shouldHideShadow {
            self.shadowView.isHidden = self.attachmentsPreviewView.isHidden
        }

        self.replyMessageView.isHidden = true
        self.someAttachmentsExist = !attachments.isEmpty
        self.badgeLabel.isHidden = attachments.isEmpty
        self.badgeLabel.badgeValue = attachments.count

        self.showAppropriateSendButton()
    }

    func update(reply: ReplyPreview?) {
        self.attachmentsPreviewView.isHidden = true
        self.replyMessageView.isHidden = reply == nil

        if let reply = reply {
            self.replyMessageView.update(sender: reply.sender, reply: reply.reply)
            self.inputTextView.becomeFirstResponder()
        }
    }

    func sendDraftWhenAppeared() {
        self.shouldSendDraftWhenAppeared = true
    }

    func showKeyboardWhenAppeared() {
        self.shouldShowKeyboardWhenAppeared = true
    }

    func addInputDecoration(_ view: UIView) {
        var arrangedSubviews = self.verticalStackView.arrangedSubviews
        arrangedSubviews.insert(view, at: 0)
        arrangedSubviews.forEach { self.verticalStackView.addArrangedSubview($0) }
    }

    func setInputAccessory(_ view: UIView?) {
        self.inputTextView.inputAccessoryView = view
    }

    func set(message: String) {
        self.inputTextView.setPreinstalledText(message)
        self.showSendButton()
    }

    func featureFlagsWereUpdated() {
        self.showAppropriateSendButton()
    }
}

extension MessageInputViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        if result == .sent {
            self.presenter.clearAllInput()
            controller.dismiss(animated: true)
            return
        }

        controller.dismiss(animated: true) {
            let alertController = UIAlertController(
                title: nil,
                message: "sms.send.failed".localized,
                preferredStyle: .alert
            )

            let cancelAction = UIAlertAction(title: "common.ok".localized, style: .cancel)
            alertController.addAction(cancelAction)

            self.topmostPresentedOrSelf.present(alertController, animated: true)
        }
    }
}

extension MessageInputViewController {
    private func promptSMS(_ text: String? = nil) {
        let text = text ?? ""

        guard MFMessageComposeViewController.canSendText() else {
            return
        }

        guard let phoneNumber = Configuration.phoneNumberToSendSMSIfNoInternet else {
            return
        }

        let alertController = UIAlertController(
            title: "error.no.internet".localized,
            message: "sms.send.prompt".localized,
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: "cancel".localized, style: .cancel)

        let sendAction = UIAlertAction(title: "sms.send".localized, style: .default) { [weak self] _ in
            guard let self = self else { return }

            let messageController = MFMessageComposeViewController()
            messageController.messageComposeDelegate = self
            messageController.recipients = [phoneNumber]
            messageController.body = text

            self.topmostPresentedOrSelf.present(messageController, animated: true)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(sendAction)

        self.topmostPresentedOrSelf.present(alertController, animated: true)
    }
}

extension MessageInputViewController: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        let oldText = textView.text as NSString?
        let newText = oldText?.replacingCharacters(in: range, with: text) ?? ""

        if textView.text.count == 0 || newText.count == 0 {
            return true
        }

        (textView as? MessageGrowingTextView)?.ignoreTextEditedNotification()
        return true
    }
}

extension MessageInputViewController: MessageInput {
    var viewController: UIViewController {
        return self
    }

    func attach(reply: ReplyPreview) {
        self.presenter.attachReply(reply)
    }

    var isWholeInputControlHidden: Bool {
        get { self.viewController.view.isHidden }
        set {
            self.viewController.view.isHidden = newValue
        }
    }

    var isVoiceButtonHidden: Bool {
        get { self.presenter.isVoiceButtonHidden }
        set {
            self.presenter.isVoiceButtonHidden = newValue
        }
    }

    func removeExistingDraft() -> MessageDraftProviding? {
        self.presenter.removeExistingDraft()
    }
}
