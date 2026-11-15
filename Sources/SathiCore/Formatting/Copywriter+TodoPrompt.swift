import Foundation

extension Copywriter {
    package static let todoDueTag = "TO-DO DUE"
    package static let todoLater = "Later"
    package static let todoDone = "Done"
    package static let todoStartIt = "Start it"
    package static let todoSwitchToIt = "Switch to it"
    package static let todoNotYet = "Not yet"
    package static let todoDueNow = "DUE NOW"
    package static let todoPickHint = "Tap a to-do to pick it."
    package static let todoAsksOnce = "Sathi asks only once."
    package static let todoQuickEarlier = "Earlier"
    package static let todoQuickToday = "Today"

    package static func todoQuickCount(_ n: Int) -> String { "\(n)" }

    package static func todoQuickOverdue(_ n: Int) -> String { "\(n) overdue" }

    package static func todoDueMessage(list: String?, running: String?) -> String {
        let due = list.map { "Due now in \($0)." } ?? "Due now."
        guard let running else { return due + " " + activityPromptNothingRuns }
        return due + " Now running: \(running). Switch ends it."
    }

    package static func todoDueDetail(list: String?, due: Date, calendar: Calendar) -> String {
        let time = trackerClock(due, calendar: calendar)
        return list.map { $0 + " · " + time } ?? time
    }
}
