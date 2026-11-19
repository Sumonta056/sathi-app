import Foundation

extension Copywriter {
    package static let dayBreakdownTitle = "Breakdown"

    package static func todaySoFarChange(_ change: RangeChange) -> String {
        rangeChange(change, kind: .day) { categoryTableHours($0) }
    }

    package static func dayBreakdownSummary(count: Int, total: TimeInterval) -> String {
        "\(count) \(count == 1 ? "category" : "categories") · \(categoryTableHours(total))"
    }
}
