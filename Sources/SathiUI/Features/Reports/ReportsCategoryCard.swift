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
                name: row.kind == .away ? Copywriter.categoryTableAwayRow(row.name) : row.name,
                colorHex: color(row, categories: categories),
                seconds: row.seconds,
                previousSeconds: row.previousSeconds
            )
        }
    }

    private static func color(_ row: ActivityRangeTotal, categories: [ActivityCategory]) -> UInt32 {
        switch row.kind {
        case .away: NightHex.trackerAway
        case .events: NightHex.trackerEvent
        case .category: ActivityColors.hex(row.isNamed ? row.name : nil, in: categories)
        }
    }
}
