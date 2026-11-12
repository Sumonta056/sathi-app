import Foundation

package enum MainPage: Equatable, Sendable {
    case today
    case activities(DayKey?)
    case reports
    case settings(SettingsPage)
}

package enum SettingsPage: Hashable, Sendable {
    case general
    case habit(HabitID)
    case quickReminders
    case tracker
    case timeBlocks
    case sound

    package static var all: [SettingsPage] {
        [.general] + HabitID.allCases.map { .habit($0) } + [.quickReminders, .tracker, .timeBlocks, .sound]
    }
}
