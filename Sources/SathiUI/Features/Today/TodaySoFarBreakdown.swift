import SathiCore
import SwiftUI

struct TodaySoFarBreakdown: View {
    let sofar: TodaySoFar
    let categories: [ActivityCategory]

    var body: some View {
        TrackerFlowLayout(spacing: UIMetrics.dayBreakdownItemGap) {
            ForEach(sofar.categories) { total in
                item(
                    name: total.name, color: ActivityColors.color(total.isNamed ? total.name : nil, in: categories),
                    seconds: total.seconds, percent: Copywriter.categoryTablePercent(total.seconds, of: sofar.logged)
                )
            }
            ForEach(sofar.away) { total in
                item(
                    name: Copywriter.categoryTableAwayRow(total.name), color: Night.category(NightHex.trackerAway),
                    seconds: total.seconds, percent: Copywriter.categoryTableNoPercent
                )
            }
        }
    }

    private func item(name: String, color: Color, seconds: TimeInterval, percent: String) -> some View {
        HStack(spacing: UIMetrics.dayBreakdownInnerGap) {
            Circle().fill(color).frame(width: UIMetrics.dayBreakdownDot, height: UIMetrics.dayBreakdownDot)
            Text(verbatim: name)
                .font(Typography.tracker(UIMetrics.dayBreakdownFont, .bold))
                .foregroundStyle(Night.text)
            Text(verbatim: Copywriter.categoryTableHours(seconds))
                .font(Typography.tracker(UIMetrics.dayBreakdownFont, .heavy))
                .foregroundStyle(Night.text)
            Text(verbatim: percent)
                .font(Typography.tracker(UIMetrics.dayBreakdownFont, .regular))
                .foregroundStyle(Night.muted)
        }
    }
}
