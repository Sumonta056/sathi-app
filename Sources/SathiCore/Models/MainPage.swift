import Foundation

package enum MainPage: Equatable, Sendable {
    case dashboard(ReportRange)
    case todos
    case activities(DayKey?)
    case calendar(DayKey?)
    case settings(SettingsPage)
}

package enum SettingsPage: Hashable, Sendable {
    case general
    case habit(HabitID)
    case quickReminders
    case tracker
    case timeBlocks
    case todos
    case sound

    package static var all: [SettingsPage] {
        [.general] + HabitID.allCases.map { .habit($0) } + [.quickReminders, .tracker, .timeBlocks, .todos, .sound]
    }
}
