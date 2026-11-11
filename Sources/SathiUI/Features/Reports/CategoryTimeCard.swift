import SathiCore
import SwiftUI

struct CategoryTimeCard: View {
    let stats: ActivityRangeStats
    let kind: ReportRange
    let categories: [ActivityCategory]

    var body: some View {
        ReportsCard {
            Text(verbatim: Copywriter.reportsCategoryTitle(kind))
                .font(Typography.rowLabel)
                .foregroundStyle(Night.text)
            if stats.categories.isEmpty {
                Text(verbatim: Copywriter.reportsNoActivities)
                    .font(Typography.hint)
                    .foregroundStyle(Night.muted)
            } else {
                ForEach(stats.categories) { row in
                    VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
                        HStack(spacing: UIMetrics.dotSpacing) {
                            Text(verbatim: row.name)
                                .font(Typography.chip)
                                .foregroundStyle(Night.text)
                            Spacer(minLength: 0)
                            Text(verbatim: Copywriter.trackerDuration(row.seconds))
                                .font(Typography.hint)
                                .foregroundStyle(Night.muted)
                            RangeChangeText(change: row.change, text: delta(row.change))
                        }
                        if row.percent > 0 {
                            ProgressBar(
                                value: Double(row.percent) / Double(Limits.fullPercent),
                                tint: color(row),
                                height: UIMetrics.trackerBarHeight,
                                track: Night.divider
                            )
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func delta(_ change: RangeChange) -> String {
        Copywriter.rangeDelta(change) { Copywriter.trackerDuration($0) }
    }

    private func color(_ row: ActivityRangeTotal) -> Color {
        row.kind == .away ? Night.trackerAway : ActivityColors.color(row.kind == .category && row.isNamed ? row.name : nil, in: categories)
    }
}
