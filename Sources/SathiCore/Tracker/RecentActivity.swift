import Foundation

package struct RecentActivity: Equatable, Hashable, Sendable {
    package var text: String
    package var category: String?
    package var length: TimeInterval

    package init(text: String, category: String?, length: TimeInterval) {
        self.text = text
        self.category = category
        self.length = length
    }
}
