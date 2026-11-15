import Foundation

package struct PromptTodo: Equatable, Sendable {
    package var id: String
    package var title: String
    package var detail: String

    package init(id: String, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

package struct PromptMarkDone: Equatable, Sendable {
    package var todoID: String
    package var question: String

    package init(todoID: String, question: String) {
        self.todoID = todoID
        self.question = question
    }
}
