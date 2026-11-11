import SathiCore
import SwiftUI

struct ReportsCategoryCard: View {
    let stats: ActivityRangeStats
    let kind: ReportRange
    let categories: [ActivityCategory]

    var body: some View {
        let table = CategoryTable(Self.inputs(stats, categories: categories))
        ReportsCard {
            Text(verbatim: Copywriter.reportsTimeByCategory)
                .font(Typography.tracker(UIMetrics.reportsCardTitleFont, .heavy))
                .foregroundStyle(Night.text)
            if table.rows.isEmpty {
                Text(verbatim: Copywriter.reportsNoActivities)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            } else {
                CategoryTableView(table: table, summary: Copywriter.reportsCategorySummary(table, kind: kind), columns: 1, showsChange: true)
            }
        }
    }

    static func inputs(_ stats: ActivityRangeStats, categories: [ActivityCategory]) -> [CategoryTableInput] {
        stats.categories.map { row in
            CategoryTableInput(
                name: row.name,
                colorHex: color(row, categories: categories),
                seconds: row.seconds,
                previousSeconds: previous(row)
            )
        }
    }

    private static func color(_ row: ActivityRangeTotal, categories: [ActivityCategory]) -> UInt32 {
        switch row.kind {
        case .away: NightHex.trackerAway
        case .events: NightHex.trackerEvent
        case .category: row.isNamed ? categories.first { $0.name == row.name }?.colorHex ?? NightHex.trackerCoral : NightHex.trackerCoral
        }
    }

    private static func previous(_ row: ActivityRangeTotal) -> TimeInterval? {
        switch row.change {
        case let .up(amount): row.seconds - amount
        case let .down(amount): row.seconds + amount
        case .same: row.seconds
        case .none: nil
        }
    }
}
