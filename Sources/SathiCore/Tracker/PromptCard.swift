import Foundation

package struct PromptCard: Equatable, Sendable {
    package var tag: String
    package var text: String
    package var category: String?
    package var detail: String
    package var progress: Double?

    package init(tag: String, text: String, category: String?, detail: String, progress: Double? = nil) {
        self.tag = tag
        self.text = text
        self.category = category
        self.detail = detail
        self.progress = progress
    }
}
