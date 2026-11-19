import SathiCore
import SwiftUI

struct DayBreakdownCard: View {
    let sofar: TodaySoFar
    let categories: [ActivityCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.dayBreakdownRowGap) {
            header
            ForEach(sofar.categories) { total in
                row(
                    name: total.name, color: ActivityColors.color(total.isNamed ? total.name : nil, in: categories),
                    seconds: total.seconds, percent: Copywriter.categoryTablePercent(total.seconds, of: sofar.logged),
                    share: Self.share(total.seconds, of: sofar.logged)
                )
            }
            ForEach(sofar.away) { total in
                row(
                    name: Copywriter.categoryTableAwayRow(total.name), color: Night.category(NightHex.trackerAway),
                    seconds: total.seconds, percent: Copywriter.categoryTableNoPercent, share: nil
                )
            }
        }
        .padding(UIMetrics.todayPanelPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .todayCard()
    }

    static func share(_ seconds: TimeInterval, of logged: TimeInterval) -> Double {
        logged > 0 ? seconds / logged : 0
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: Copywriter.dayBreakdownTitle)
                .font(Typography.tracker(UIMetrics.todayPanelTitleFont, .heavy))
                .foregroundStyle(Night.text)
            Spacer(minLength: UIMetrics.dayBreakdownInnerGap)
            Text(verbatim: Copywriter.dayBreakdownSummary(count: sofar.categories.count, total: sofar.logged))
                .font(Typography.tracker(UIMetrics.todayComingDetailFont, .regular))
                .foregroundStyle(Night.muted)
                .lineLimit(1)
        }
    }

    private func row(name: String, color: Color, seconds: TimeInterval, percent: String, share: Double?) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.dayBreakdownLineGap) {
            HStack(spacing: UIMetrics.dayBreakdownInnerGap) {
                Circle().fill(color).frame(width: UIMetrics.dayBreakdownDot, height: UIMetrics.dayBreakdownDot)
                Text(verbatim: name)
                    .font(Typography.tracker(UIMetrics.dayBreakdownFont, .bold))
                    .foregroundStyle(share == nil ? Night.muted : Night.text)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(verbatim: Copywriter.categoryTableHours(seconds))
                    .font(Typography.tracker(UIMetrics.dayBreakdownFont, .heavy))
                    .foregroundStyle(Night.text)
                Text(verbatim: percent)
                    .font(Typography.tracker(UIMetrics.dayBreakdownFont, .regular))
                    .foregroundStyle(Night.muted)
                    .frame(width: UIMetrics.dayBreakdownPercentWidth, alignment: .trailing)
            }
            if let share { bar(share, color) }
        }
    }

    private func bar(_ share: Double, _ color: Color) -> some View {
        GeometryReader { g in
            Capsule().fill(Night.border)
                .overlay(alignment: .leading) { Capsule().fill(color).frame(width: g.size.width * share) }
        }
        .frame(height: UIMetrics.dayBreakdownBarHeight)
        .accessibilityIdentifier("day.breakdown.bar")
    }
}
