import Foundation
import SathiCore
import SwiftUI

enum DashboardContent: Equatable {
    case today
    case all
    case buddy(HabitID)
}

extension DashboardPage {
    static func content(range: StatsRange, now: Date, selected: HabitID?) -> DashboardContent {
        if let selected { return .buddy(selected) }
        return range.kind == .day && range.holds(now) ? .today : .all
    }
}
