import UIKit

public final class ChatViewController: UIViewController {
    private static let defaultAnimationTimeInterval: TimeInterval = 0.25

    private let presenter: ChatPresenterProtocol

    // Chat
    private let messagesListViewController: MessagesListViewControllerProtocol
    private let messageInputViewController: MessageInputViewControllerProtocol

    // Message sender
    private var messageInputBottomConstraint: NSLayoutConstraint?
    private var safeAreaPlaceholderHeightConstraint: NSLayoutConstraint?
    private var chatViewToSenderViewConstraint: NSLayoutConstraint?
    private var chatViewToBottomConstraint: NSLayoutConstraint?
    
    // Keyboard tracker
    private var keyboardHeightTracker: KeyboardHeightTracker?
    private var didAppear: Bool = false

    // Safe area zone view
    private lazy var safeAreaPlaceholderView = UIView()

    private var themeProvider: ThemeProvider?

    private var isMessageInputViewVisible: Bool {
        !self.messageInputViewController.viewController.view.isHidden
    }

    private var isMessageInputViewEditing: Bool {
        self.messageInputViewController.viewController.view.firstSubview(matching: { $0.isFirstResponder }) != nil
    }

    init(
        messagesListViewController: MessagesListViewControllerProtocol,
        messageInputViewController: MessageInputViewControllerProtocol,
        presenter: ChatPresenterProtocol
    ) {
        self.presenter = presenter

        self.messagesListViewController = messagesListViewController
        self.messageInputViewController = messageInputViewController

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.themeProvider = ThemeProvider(themeUpdatable: self)

        self.setupChildControllers()
        self.startTrackingKeyboard()
        self.presenter.loadInitialMessages()
    }
    
    private func startTrackingKeyboard() {
        self.keyboardHeightTracker = .init(view: self.view) { [weak self] height in
            self?.messageInputBottomConstraint?.constant = -height
        }

        self.keyboardHeightTracker?.onWillShowKeyboard = { [weak self] in
            self?.toggleSafeAreaPlaceholder(isVisible: false)
        }

        self.keyboardHeightTracker?.onWillHideKeyboard = { [weak self] in
            let isVisible = self?.isMessageInputViewVisible ?? false
            self?.toggleSafeAreaPlaceholder(isVisible: isVisible)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.chatViewToSenderViewConstraint?.isActive = self.isMessageInputViewVisible
        self.chatViewToBottomConstraint?.isActive = !self.isMessageInputViewVisible

        let mayShowSafeAreaPlaceholder = self.isMessageInputViewVisible && !self.isMessageInputViewEditing
        self.toggleSafeAreaPlaceholder(isVisible: mayShowSafeAreaPlaceholder)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.didAppear = true
        self.keyboardHeightTracker?.areAnimationsEnabled = true
        self.presenter.didAppear()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateChatContentInset()
    }

    // MARK: - Private

    private func updateChatContentInset() {
        let topOffset = self.topLayoutGuide.length
        
        var chatContentInset = UIEdgeInsets(top: topOffset, left: 0, bottom: 0, right: 0)
        if #available(iOS 11.0, *),
           !self.isMessageInputViewVisible,
           self.presenter.shouldShowSafeAreaView,
           let insets = UIWindow.keyWindow?.safeAreaInsets {
            chatContentInset.bottom = insets.bottom
        }
        
        if presenter.bottomViewExists {
            let bottomInset = view.safeAreaInsets.bottom + 44 + 20 // set when have new request button
            messagesListViewController.adjustContentInsets(top: chatContentInset.top, bottom: bottomInset)
        } else {
            messagesListViewController.adjustContentInsets(top: chatContentInset.top, bottom: chatContentInset.bottom)
        }
    }

    private func setupChildControllers() {
        guard let view = self.view,
              let chatView = self.messagesListViewController.view,
              let senderView = self.messageInputViewController.view else {
            return
        }

        // Chat

        self.addChild(self.messagesListViewController)
        self.messagesListViewController.didMove(toParent: self)

        view.addSubview(chatView)
        chatView.translatesAutoresizingMaskIntoConstraints = false
        chatView.topAnchor.constraint(equalTo: self.topLayoutGuide.topAnchor).isActive = true
        chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.chatViewToBottomConstraint = chatView.bottomAnchor.constraint(
            equalTo: self.safeAreaPlaceholderView.topAnchor
        )

        // Sender

        self.addChild(self.messageInputViewController)
        self.messageInputViewController.didMove(toParent: self)

        view.addSubview(senderView)
        senderView.translatesAutoresizingMaskIntoConstraints = false
        senderView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        senderView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        self.chatViewToSenderViewConstraint = senderView.topAnchor.constraint(equalTo: chatView.bottomAnchor)

        view.addSubview(self.safeAreaPlaceholderView)
        self.safeAreaPlaceholderView.translatesAutoresizingMaskIntoConstraints = false
        self.safeAreaPlaceholderView.topAnchor.constraint(equalTo: senderView.bottomAnchor).isActive = true
        self.safeAreaPlaceholderView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        self.safeAreaPlaceholderView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        self.messageInputBottomConstraint = self.safeAreaPlaceholderView
            .bottomAnchor
            .constraint(equalTo: view.bottomAnchor)
        self.messageInputBottomConstraint?.isActive = true
        
        self.safeAreaPlaceholderHeightConstraint = self.safeAreaPlaceholderView
            .heightAnchor
            .constraint(equalToConstant: 0)
        self.safeAreaPlaceholderHeightConstraint?.isActive = true
        
        self.toggleSafeAreaPlaceholder(isVisible: true)
    }
    
    private func toggleSafeAreaPlaceholder(isVisible: Bool) {
        let shouldShowSafeAreaView = self.presenter.shouldShowSafeAreaView
        
        guard #available(iOS 11.0, *),
              let insets = UIWindow.keyWindow?.safeAreaInsets,
              shouldShowSafeAreaView else {
            return
        }

        let height = isVisible ? insets.bottom : 0.0
        self.safeAreaPlaceholderHeightConstraint?.constant = height
    }
}

extension ChatViewController: ThemeUpdatable {
    public func update(with theme: Theme) {
        self.view.backgroundColor = UIColor(patternImage: theme.imageSet.chatBackground)
        self.safeAreaPlaceholderView.backgroundColor = theme.palette.senderBackground
    }
}

extension ChatViewController: ChatProtocol {
    public func addBottomView(_ view: UIView) {
        self.messagesListViewController.addBottomView(view)
    }

    public var viewController: UIViewController {
        return self
    }

    public func sendMessage(sender: ContentSender) {
        self.presenter.sendMessage(nil, sender: sender, completion: nil)
    }

    public func sendMessage(text: String, completion: ((Bool) -> Void)?) {
        let sender = TextContentSender(guid: nil, text: text, reply: nil)
        self.presenter.sendMessage(sender: sender, completion: completion)
    }

    public func retryFailedMessage(with id: String) {
        self.presenter.retryMessageSending(guid: id)
    }

    public func sendDraftWhenAppeared() {
        self.messageInputViewController.sendDraftWhenAppeared()
    }

    public func showKeyboardWhenAppeared() {
        self.messageInputViewController.showKeyboardWhenAppeared()
    }

    public func setInputAccessory(_ view: UIView?) {
        self.messageInputViewController.setInputAccessory(view)
    }

    public func addInputDecoration(_ view: UIView) {
        self.messageInputViewController.addInputDecoration(view)
    }

    public var isVoiceButtonHidden: Bool {
        get {
            self.messageInputViewController.isVoiceButtonHidden ?? false
        }
        set {
            self.messageInputViewController.isVoiceButtonHidden = newValue
        }
    }

    public var isWholeInputControlHidden: Bool {
        get {
            self.messageInputViewController.isWholeInputControlHidden ?? false
        }
        set {
            self.messageInputViewController.isWholeInputControlHidden = newValue
        }
    }

    public func setOverlay(_ view: UIView) {
        self.messagesListViewController.setOverlay(view)
    }

    public func updateInput(with draft: MessageDraftProviding?) {
        guard let draft = draft else {
            self.removeExistingDraft()
            return
        }

        self.presenter.saveDraft(
            messageGUID: draft.guid,
            messageStatus: .draft,
            text: draft.text,
            attachments: draft.attachments
        )
    }

    @discardableResult
    public func removeExistingDraft() -> MessageDraftProviding? {
        self.messageInputViewController.removeExistingDraft()
    }
}
