import Foundation

package struct TodoPageModel: Equatable {
    package var selection: TodoSelection
    package var title: String
    package var open: [Todo]
    package var completed: [Todo]
    package var canAdd: Bool
    package var targetListID: String?

    package init(selection: TodoSelection, title: String, open: [Todo], completed: [Todo], targetListID: String?) {
        self.selection = selection
        self.title = title
        self.open = open
        self.completed = completed
        self.targetListID = targetListID
        canAdd = targetListID != nil
    }
}
