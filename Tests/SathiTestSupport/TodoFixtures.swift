import Foundation
import SathiCore

package func makeTodo(
    _ id: String,
    _ title: String = "Task",
    list: String = "inbox",
    due: TodoDue? = nil,
    done: Bool = false,
    doneAt: Date? = nil,
    created: Date = Date(timeIntervalSince1970: 1_800_000_000)
) -> Todo {
    Todo(
        id: id,
        listID: list,
        title: title,
        notes: "",
        due: due,
        priority: 0,
        isDone: done,
        doneAt: doneAt,
        createdAt: created,
        repeats: false,
        url: nil
    )
}

package func makeTodoList(_ id: String, _ name: String = "List") -> TodoList {
    TodoList(id: id, name: name, colorHex: "#FF3B30", accountID: "icloud", accountName: "iCloud", canEdit: true)
}
