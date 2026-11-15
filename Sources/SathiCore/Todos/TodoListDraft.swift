import Foundation

package struct TodoListDraft: Equatable, Sendable {
    package var name: String
    package var colorHex: String
    package var accountID: String

    package init(name: String, colorHex: String, accountID: String) {
        self.name = name
        self.colorHex = colorHex
        self.accountID = accountID
    }

    package var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    package var isValid: Bool { !trimmedName.isEmpty && Limits.todoListColors.contains(colorHex) }
}
