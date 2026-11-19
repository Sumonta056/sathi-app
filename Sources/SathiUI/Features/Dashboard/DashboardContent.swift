import Foundation
import SathiCore

enum DashboardContent: Equatable {
    case today
    case all
    case buddy(HabitID)
}

extension DashboardPage {
    static func content(range: StatsRange, now: Date, selected: HabitID?) -> DashboardContent {
        fatalError("Track B")
    }
}
