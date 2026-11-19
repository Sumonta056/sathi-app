import Foundation

extension Copywriter {
    package static let mainPageDashboard = "Dashboard"
    package static let sidebarPlanHeading = "PLAN"

    package static func dashboardScoreLine(met: Int, possible: Int, change: String) -> String {
        let goals = "\(met) of \(possible) goals today"
        return change.isEmpty ? goals : goals + " · " + change
    }
}
