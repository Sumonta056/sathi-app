import SathiCore

enum SettingsTab: Hashable {
    case general
    case habit(HabitID)
    case timeBlocks
    case addBuddy
}
