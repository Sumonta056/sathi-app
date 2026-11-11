import Foundation

extension Copywriter {
    package static let mainPageToday = "Today"
    package static let mainAppName = "Sathi"
    package static let mainPageActivities = "Activities"
    package static let mainPageReports = "Reports"
    package static let mainPageSettings = "Settings"
    package static let mainTrackerOn = "TRACKER ON"
    package static let mainTrackerOff = "TRACKER OFF"
    package static let mainMenuFile = "File"
    package static let mainMenuClose = "Close"

    package static func mainTrackerHours(_ start: Date, _ end: Date, askEvery: Int, calendar: Calendar) -> String {
        trackerSpan(start, end, calendar: calendar) + " · asks every \(askEvery) min"
    }

    package static func settingsPageTitle(_ page: SettingsPage) -> String {
        switch page {
        case .general: return "General"
        case let .habit(id): return id.buddy
        case .quickReminders: return "Quick reminders"
        case .tracker: return "Activity tracker"
        case .timeBlocks: return blockSettingsTitle
        case .sound: return "Sound"
        }
    }
}
