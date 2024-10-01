import UIKit
import ChatSDK

final class StartTableViewController: UIViewController {
    private let items = ["Default", "PRIME", "WRF", "PRIME PARK", "Prime App"]

    private var currentChat: Chat?
    private weak var chatViewController: UIViewController?

    @IBAction func onSubscriptionsTap(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Авторизация", message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Client ID"
        }

        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)

        let saveAction = UIAlertAction(
            title: "Далее",
            style: .default,
            handler: { [weak self] alert in
                let clientID = ((alertController.textFields![0] as UITextField).text ?? "")

                if !clientID.isEmpty {
                    self?.testSubscriptions(clientID: clientID)
                }
            }
        )

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        self.present(alertController, animated: true, completion: nil)
    }

    private func testSubscriptions(clientID: String) {
        let token = Self.encodeAccessToken(clientID: clientID)
        let chatBaseURL = URL(string: "https://chat.technolab.com.ru/chat-server/v3")!
        let storageBaseURL = URL(string: "https://chat.technolab.com.ru/storage")!

        let configuration = Chat.Configuration(
            chatBaseURL: chatBaseURL,
            storageBaseURL: storageBaseURL,
            initialTheme: Theme.default,
            shouldDisableLogging: false
        )

        let chat = Chat(
            configuration: configuration,
            accessToken: token,
            clientID: clientID
        )

        self.currentChat = chat
        chat.getSubscriptions { [weak self] result in
            var text = ""

            switch result {
            case .failure(let error):
                text += "==> Subscriptions error: \(error.localizedDescription)\n"
            case .success(let channels):
                text += "==> Subscriptions:\n"

                func contentPreviewsArrayToString(_ array: [ChannelMessagePreview.ContentPreview]) -> String {
                    var res = ""
                    for preview in array {
                        res += "    \(preview.prebuilt?.debugDescription ?? "<empty>")\n"
                    }
                    return res
                }

                for channel in channels {
                    text += "  [\(channel.id)] (+\(channel.unreadCount) unread)\n"
                    if let lastMessage = channel.lastMessage {
                        text += "   \(lastMessage.timestamp) \(lastMessage.status == .draft ? " DRAFT" : "")\n"
                        text += "\(contentPreviewsArrayToString(lastMessage.content))\n"
                    } else {
                        text += "  no last message"
                    }
                }

                let alert = UIAlertController(title: nil, message: text, preferredStyle: .actionSheet)
                alert.addAction(.init(title: "Close", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }

            self?.currentChat = nil
        }
    }

    private func presentTestChatAuth(completion: @escaping (String, String) -> Void) {
        let alertController = UIAlertController(title: "Авторизация", message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Client ID"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Channel ID"
        }

        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel, handler: nil)

        let saveAction = UIAlertAction(
            title: "Далее",
            style: .default,
            handler: { [weak self] alert in
                let clientID = ((alertController.textFields![0] as UITextField).text ?? "")
                let channelID = ((alertController.textFields![1] as UITextField).text ?? "")

                if clientID.isEmpty || channelID.isEmpty {
                    self?.presentTestChatAuth(completion: completion)
                } else {
                    completion(clientID, channelID)
                }
            }
        )

        alertController.addAction(cancelAction)
        alertController.addAction(saveAction)

        self.present(alertController, animated: true, completion: nil)
    }

    private static func encodeAccessToken(clientID: String) -> String {
        return Data("\(clientID):d2hpdGVfcmFiYml0X2ZhbWlseQ==".utf8).base64EncodedString()
    }
}

extension StartTableViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = self.items[indexPath.item]
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.presentTestChatAuth { clientID, channelID in
            let token = Self.encodeAccessToken(clientID: clientID)
            let chatBaseURL = URL(string: "https://chat.technolab.com.ru/chat-server/v3")!
            let storageBaseURL = URL(string: "https://chat.technolab.com.ru/storage")!

            let configuration: Chat.Configuration

            switch indexPath.item {
            case 0:
                configuration = Chat.Configuration(
                    chatBaseURL: chatBaseURL,
                    storageBaseURL: storageBaseURL,
                    initialTheme: Theme.default,
                    shouldDisableLogging: false
                )
            case 1:
                configuration = Chat.Configuration(
                    chatBaseURL: chatBaseURL,
                    storageBaseURL: storageBaseURL,
                    initialTheme: PrimeStyle.theme,
                    shouldDisableLogging: false
                )
            case 2:
                configuration = Chat.Configuration(
                    chatBaseURL: chatBaseURL,
                    storageBaseURL: storageBaseURL,
                    initialTheme: WRFStyle.theme,
                    featureFlags: Chat.Configuration.FeatureFlags.all(except: .canSendContactMessage),
                    shouldDisableLogging: false
                )
            case 3:
                configuration = Chat.Configuration(
                    chatBaseURL: chatBaseURL,
                    storageBaseURL: storageBaseURL,
                    initialTheme: PrimeParkStyle.theme,
                    shouldDisableLogging: false
                )
            case 4:
                configuration = Chat.Configuration(
                    chatBaseURL: chatBaseURL,
                    storageBaseURL: storageBaseURL,
                    initialTheme: PrimeAppStyle.theme,
                    featureFlags: .all(
                        except: [
                            .canSendLocationMessage,
                            .canSendContactMessage,
                            .canSendImageAndVideoMessage,
                            .showSenderShadow,
                            .canSendVoiceMessage,
                            .canSendFileMessage,
                            .canUseDrafts,
                            .canReadReceipts
                        ]
                    ),
                    shouldDisableLogging: false
                )
            default:
                fatalError("Undefined segue")
            }

            let chat = Chat(
                configuration: configuration,
                accessToken: token,
                clientID: clientID
            )

            let channelModule = chat.makeChannelModule(
                for: channelID,
                output: self,
                messageTypesToIgnore: ["TASK_LINK"]
            )

            let controller = channelModule.viewController

            switch indexPath.item {
            case let x where x != 3:
                let navigationController = UINavigationController(rootViewController: controller)
                self.present(navigationController, animated: true) { [weak self] in
                    self?.chatViewController = navigationController
                }
            case 3:
                self.navigationController?.pushViewController(controller, animated: true)
                self.chatViewController = controller
            default: break
            }
        }
    }
}

extension StartTableViewController: ChannelModuleOutputProtocol {
	func decideIfMaySendMessage() -> Bool {
		true
	}

	func modifyTextBeforeSending(_ text: String) -> String {
		text
	}

    var shouldShowSafeAreaView: Bool { true }

    func requestPhoneCall(number: String) {
        if let url = URL(string: "tel://\(number)"), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }

    func requestPresentation(for controller: UIViewController, completion: (() -> Void)?) {
        self.chatViewController?.present(controller, animated: true, completion: completion)
    }

	func didMessageSendingStatusUpdate(with status: ChannelMessageSendingStatus, preview: ChannelMessagePreview) {
		print("update message status: \(status) for \(preview.channelID)")
    }

    func didChannelControllerStatusUpdate(with status: ChannelControllerStatus) {
        print("update channel status: \(status)")
    }

    func didTextViewEditingStatusUpdate(with value: Bool) {
        print("update text view status: \(value)")
    }

    func didChannelAttachmentsUpdate(_ update: ChannelAttachmentsUpdate, totalCount: Int) {
        print("update attachments: \(update), count \(totalCount)")
    }

    func didChannelVoiceMessageStatusUpdate(with status: ChannelVoiceMessageStatus) {
        print("update voice message status: \(status)")
    }
}
