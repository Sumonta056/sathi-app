import SathiCore

enum SettingsTab: Hashable {
    case general
    case habit(HabitID)
    case timeBlocks
    case tracker
    case addBuddy
}

extension SettingsTab {
    init(_ page: SettingsPage) {
        switch page {
        case let .habit(id): self = .habit(id)
        case .timeBlocks: self = .timeBlocks
        case .tracker: self = .tracker
        case .general, .quickReminders, .sound: self = .general
        }
    }
}
