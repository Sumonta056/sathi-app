import SathiCore
import SwiftUI

struct CalendarStatsPanel: View {
    let stats: CalendarPageStats
    let kind: ReportRange
    let categories: [ActivityCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.calendarSideGap) {
            CalendarSideCard(title: Copywriter.calendarStatsTitle(kind)) {
                row(Copywriter.calendarTracked, stats.tracked, dot: nil)
                row(Copywriter.calendarPlannedEvents, stats.planned, dot: nil)
                row(Copywriter.calendarAway, stats.away, dot: nil)
            }
            CalendarSideCard(title: Copywriter.calendarByCategory) {
                if stats.byCategory.isEmpty {
                    Text(verbatim: Copywriter.calendarNothingTracked)
                        .font(Typography.hint)
                        .foregroundStyle(Night.faint)
                } else {
                    ForEach(stats.byCategory, id: \.name) { c in
                        row(c.name ?? Copywriter.trackerNoCategory, c.seconds, dot: ActivityColors.color(c.name, in: categories))
                    }
                }
            }
            CalendarShownList()
        }
    }

    private func row(_ label: String, _ seconds: TimeInterval, dot: Color?) -> some View {
        HStack(spacing: UIMetrics.calendarSideRowSpacing) {
            if let dot {
                Circle().fill(dot).frame(width: UIMetrics.calendarSideDot, height: UIMetrics.calendarSideDot)
            }
            Text(verbatim: label)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(verbatim: Copywriter.calendarHours(seconds))
                .font(Typography.chip)
                .foregroundStyle(Night.text)
        }
    }
}
