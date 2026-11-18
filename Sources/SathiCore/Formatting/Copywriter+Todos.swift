import Foundation

extension Copywriter {
    package static let todoDueToday = "Due today"
    package static let todoAllowAccess = "Allow Reminders access"
    package static let todoOpenSettings = "Open System Settings"

    package static func todoSmartListName(_ list: TodoSmartList) -> String {
        switch list {
        case .today: "Today"
        case .scheduled: "Scheduled"
        case .all: "All"
        case .completed: "Completed"
        }
    }

    package static func todoCompletedToggle(_ n: Int) -> String { "\(n) Completed · Show" }

    package static func todoPageCount(open: Int, lists: Int?) -> String {
        let head = "\(open) open"
        guard let lists else { return head }
        return head + " · \(lists) " + (lists == 1 ? "list" : "lists")
    }

    package static func todoMarkDoneTitle(_ title: String) -> String { "Mark \(title) done?" }

    package static func todoDaySummaryLine(done: Int, left: Int) -> String {
        "To-dos: \(done) done · \(left) left for today"
    }
}
