import Foundation

extension Copywriter {
    package static let settingsEyebrow = "SETTINGS"
    package static let settingsSaveNote = "Settings save at once."
    package static let settingsSoundLink = "Session sound is on the Sound page."
    package static let settingsSoftSounds = "Play soft sounds"
    package static let settingsSoftSoundsHint = "A tiny pop when a buddy says hi."

    package static func settingsHeaderTitle(_ page: SettingsPage) -> String {
        switch page {
        case let .habit(id): return "\(id.buddy) · \(id.name.lowercased())"
        case .general, .quickReminders, .tracker, .timeBlocks, .sound: return settingsPageTitle(page)
        }
    }

    package static func settingsOnLabel(_ id: HabitID) -> String { "\(id.name) reminders" }
}
