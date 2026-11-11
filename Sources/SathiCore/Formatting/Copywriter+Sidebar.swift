import Foundation

extension Copywriter {
    package static let sidebarOpenLabel = "Open sidebar"
    package static let sidebarCloseLabel = "Close sidebar"
    package static let sidebarSettingsHeading = "SETTINGS"
    package static let sidebarGitHub = "GitHub"
    package static let sidebarPortfolio = "Portfolio"
    package static let sidebarTrackerOnHint = "Tracker on"
    package static let sidebarTrackerOffHint = "Tracker off"

    package static func sidebarSettingsTitle(_ page: SettingsPage) -> String {
        switch page {
        case let .habit(id): return "\(id.buddy) · \(habitWord(id))"
        case .general, .quickReminders, .tracker, .timeBlocks, .sound: return settingsPageTitle(page)
        }
    }

    package static func sidebarFooter(version: String?) -> String {
        guard let version else { return "Sathi · by Sumonta" }
        return "Sathi \(version) · by Sumonta"
    }

    package static func sidebarVersion(_ version: String?) -> String {
        version ?? mainAppName
    }

    private static func habitWord(_ id: HabitID) -> String {
        switch id {
        case .water: return "water"
        case .reading: return "reading"
        case .meditation: return "calm"
        case .gym: return "gym"
        }
    }
}
