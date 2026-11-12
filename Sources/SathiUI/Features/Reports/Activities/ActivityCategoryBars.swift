import SathiCore
import SwiftUI

struct ActivityCategoryBars: View {
    let totals: [ActivityCategoryTotal]
    let categories: [ActivityCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerBarsSpacing) {
            ForEach(totals) { row in
                HStack(spacing: UIMetrics.reportsGap) {
                    Text(verbatim: row.name)
                        .font(Typography.chip)
                        .foregroundStyle(Night.text)
                        .frame(width: UIMetrics.trackerBarsNameWidth, alignment: .leading)
                    ProgressBar(
                        value: Double(row.percent) / Double(Limits.fullPercent),
                        tint: ActivityColors.color(row.isNamed ? row.name : nil, in: categories),
                        height: UIMetrics.trackerBarHeight,
                        track: Night.divider
                    )
                    Text(verbatim: Copywriter.trackerDuration(row.seconds))
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                        .frame(width: UIMetrics.trackerBarsLengthWidth, alignment: .trailing)
                }
            }
        }
    }
}
