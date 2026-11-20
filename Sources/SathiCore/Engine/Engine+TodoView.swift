import Foundation

extension Engine {
    package func setTodoAllView(_ view: TodoAllView) {
        data.prefs.todos.allView = view
    }

    package func setTodoSideHidden(_ hidden: Bool) {
        data.prefs.todos.sideHidden = hidden
    }
}
