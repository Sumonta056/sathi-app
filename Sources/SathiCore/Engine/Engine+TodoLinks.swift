import Foundation

extension Engine {
    package func openTodoLink(_ url: URL) {
        guard TodoTitlePart.isWeb(url) else { return }
        links.open(url)
    }
}
