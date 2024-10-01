import UIKit

final class ContactContentRenderer: ContentRenderer {
    static let messageContentType: MessageContent.Type = ContactContent.self

    static var messageModelType: MessageModel.Type {
        return MessageContainerModel<ContactContentView>.self
    }

    private let content: ContactContent
    private let contentMeta: ContentMeta
    private let actions: ContentRendererActions
    private let dependencies: ContentRendererDependencies

    private var onContentOpened: MessageContentOpeningCompletion?
    
    private var contact: ContactItem?

    private var contactFileViewModel: ContactContentView.Model? {
        self.contact.flatMap { ContactContentView.Model(name: $0.fullName, phone: $0.phone ?? "–") }
    }

    private var contactMetaViewModel: ContactContentView.Model? {
        if let name = self.contentMeta.contactName {
            return ContactContentView.Model(name: name, phone: self.contentMeta.contactPhone ?? "–")
        }
        return nil
    }

    private var controlValue: Int {
        self.contactMetaViewModel?.name.hashValue ?? self.contactFileViewModel?.name.hashValue ?? 0
    }

    private init(
        content: ContactContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) {
        if case .local(let data) = content.content {
            self.contact = ContactItem(data: data)
        }

        self.content = content
        self.contentMeta = contentMeta
        self.actions = actions
        self.dependencies = dependencies

        self.downloadVCard()
    }

    static func make(
        for content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) -> ContentRenderer {
        guard let content = content as? ContactContent else {
            fatalError("Incorrect content type")
        }

        // Swift.print("WILL MAKE FOR GUID: \(content.messageGUID ?? "") \(Self.self)")

        return ContactContentRenderer(
            content: content,
            contentMeta: contentMeta,
            actions: actions,
            dependencies: dependencies
        )
    }

    func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel {
        var actions = self.actions
        actions.openContent = { completion in
            if self.contact != nil {
                self.makeCall()
                completion()
                return
            }
            self.onContentOpened = completion
        }
        
        return MessageContainerModel<ContactContentView>(
            uid: uid,
            meta: meta,
            contentControlValue: self.controlValue,
            shouldCalculateHeightOnMainThread: false,
            actions: actions,
            contentConfigurator: { view in
                if let metaModel = self.contactMetaViewModel {
                    view.update(model: metaModel, meta: meta)
                } else if let fileModel = self.contactFileViewModel {
                    view.update(model: fileModel, meta: meta)
                } else {
                    view.update(model: nil, meta: meta)

                    // TODO @v.kiryukhin: potentially race condition, avoid request duplication
                    self.downloadVCard { [weak view] in
                        self.contactFileViewModel.flatMap { view?.update(model: $0, meta: meta) }
                        if let completion = self.onContentOpened {
                            self.onContentOpened = nil
                            self.makeCall()
                            completion()
                        }
                    }
                }

                view.onTap = { [weak self] in
                    self?.makeCall()
                }
            },
            heightCalculator: { _, _ in
                ContactContentView.height
            }
        )
    }

    func preview() -> MessagePreview.ProcessedContent? {
        .contact(name: self.contentMeta.contactName)
    }

    // MARK: - Private

    private func downloadVCard(completion: (() -> Void)? = nil) {
        guard case .remote(let path) = self.content.content,
              let file = FileInfo(remotePath: path) else {
            return
        }

        dependencies.fileService.downloadAndDecode(
            file: file,
            skipCache: false,
            onMainQueue: false
        ) { [weak self] (contact: ContactItem?) in
            guard let contact else {
                delay(1) {
                    self?.downloadVCard(completion: completion)
                }
                return
            }
            self?.contact = contact
            completion?()
        }
    }

    private func makeCall() {
        self.contact?.phone.flatMap {
            self.dependencies.chatDelegate?.requestPhoneCall(number: $0)
        }
    }
}
