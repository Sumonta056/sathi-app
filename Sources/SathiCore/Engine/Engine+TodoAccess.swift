import Foundation

extension Engine {
    static let remindersPrivacyURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders")!

    package func setTodosOn(_ on: Bool) async {
        data.prefs.todos.isOn = on
        guard on else { return }
        if todos.access == .notAsked { _ = await todos.requestAccess() }
        todoRuntime.stale = true
        await refreshTodosNow()
    }

    package func requestTodoAccess() async {
        _ = await todos.requestAccess()
        todoRuntime.stale = true
        await refreshTodosNow()
    }

    package func openTodoSettings() {
        links.open(Self.remindersPrivacyURL)
    }
}
