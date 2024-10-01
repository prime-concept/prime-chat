import Foundation

final class ContentRendererFactory {
    private(set) var presenters: [ContentRenderer.Type] = []

    func register(presenter: ContentRenderer.Type) {
        self.presenters.append(presenter)
    }

    func make(
        for content: MessageContent,
        contentMeta: ContentMeta,
        actions: ContentRendererActions,
        dependencies: ContentRendererDependencies
    ) -> ContentRenderer {
        guard let presenterType = self.presenters.first(
            where: {$0.messageContentType == type(of: content)}
        ) else {
            fatalError("Unknown content type")
        }
        return presenterType.make(
            for: content,
            contentMeta: contentMeta,
            actions: actions,
            dependencies: dependencies
        )
    }
}
