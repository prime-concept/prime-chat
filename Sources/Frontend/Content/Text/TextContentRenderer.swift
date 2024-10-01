import UIKit

final class TextContentRenderer: ContentRenderer {
    static let messageContentType: MessageContent.Type = TextContent.self

    static var messageModelType: MessageModel.Type {
        return MessageContainerModel<TextContentView>.self
    }

    private let content: TextContent
    private let actions: ContentRendererActions
    private let dependencies: ContentRendererDependencies

    private init(
        content: TextContent,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) {
        self.content = content
        self.actions = actions
        self.dependencies = dependencies
    }

    static func make(
        for content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) -> ContentRenderer {
        guard let content = content as? TextContent else {
            fatalError("Incorrect content type")
        }

        return TextContentRenderer(content: content, actions: actions, dependencies: dependencies)
    }

    func messageModel(with uid: String, meta: MessageContainerModelMeta) -> MessageModel {
        var actions = self.actions
        actions.openContent = { completion in
            completion()
        }

        return MessageContainerModel<TextContentView>(
            uid: uid,
            meta: meta,
            contentControlValue: self.content.string.hashValue,
            shouldCalculateHeightOnMainThread: false,
            actions: actions,
            contentConfigurator: { [content, meta] view in
                Self.configureView(view, with: content, meta: meta)
            },
            heightCalculator: { [content] width, infoViewArea in
                Self.calculateHeight(
                    maxWidth: width,
                    hasReply: meta.replyMeta != nil,
                    content: content,
                    infoViewArea: infoViewArea
                )
            }
        )
    }

    func preview() -> MessagePreview.ProcessedContent? {
        .text(self.content.string)
    }

    // MARK: - Private

    private static func configureView(
        _ view: TextContentView,
        with content: TextContent,
        meta: MessageContainerModelMeta
    ) {
        view.update(with: content.string, meta: meta)
    }

    private static func calculateHeight(
        maxWidth: CGFloat,
        hasReply: Bool,
        content: TextContent,
        infoViewArea: CGSize
    ) -> CGFloat {
        let size = TextContentView.calculateSize(
            for: content.string,
            maxWidth: maxWidth,
            hasReply: hasReply,
            maxPossibleRightBottomAreaSize: infoViewArea
        )

        if size.width > maxWidth {
            assertionFailure(
                """
                Calculated width is greater than max width:
                    maxWidth = \(maxWidth)
                    calculatedWidth = \(size.width)
                    text = \(content.string)
                """
            )
        }

        return size.height
    }
}
