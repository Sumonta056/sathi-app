import Foundation

package struct TodoList: Equatable, Sendable {
    package var id: String
    package var name: String
    package var colorHex: String
    package var accountID: String
    package var accountName: String
    package var canEdit: Bool

    package init(id: String, name: String, colorHex: String, accountID: String, accountName: String, canEdit: Bool) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.accountID = accountID
        self.accountName = accountName
        self.canEdit = canEdit
    }
}

package struct TodoAccount: Equatable, Sendable {
    package var id: String
    package var name: String
    package var allowsNewLists: Bool

    package init(id: String, name: String, allowsNewLists: Bool) {
        self.id = id
        self.name = name
        self.allowsNewLists = allowsNewLists
    }
}
