import SathiCore
import SwiftUI

struct StreakOverviewCard: View {
    @EnvironmentObject var e: Engine
    let start: StatsRange
    @State private var picked: StatsRange?
    @State private var memo = RangeMemo<StatsRange, OverviewMonth>()

    var body: some View {
        let month = picked ?? start
        let data = memo.value(month, range: month, engine: e) { $0.streakOverview($1) }
        StreakOverviewView(month: data) { step in
            picked = step < 0 ? month.previous : month.next
        }
    }
}

struct StreakOverviewView: View {
    let month: OverviewMonth
    var step: (Int) -> Void = { _ in }

    var body: some View {
        ReportsCard {
            MonthHeader(title: month.title, canGoForward: month.canGoForward, step: step) {
                Text(verbatim: month.streakText)
                    .font(Typography.tracker(UIMetrics.reportsMonthFont, .heavy))
                    .foregroundStyle(Night.sprout)
            }
            MonthGrid(leadingBlanks: month.leadingBlanks, count: month.days.count) { index in
                OverviewDayCell(day: month.days[index])
            }
            legend
        }
        .frame(width: UIMetrics.reportsCalendarWidth)
    }

    private var legend: some View {
        HStack(spacing: UIMetrics.reportsLegendGap) {
            ForEach(HabitID.allCases) { id in
                HStack(spacing: UIMetrics.reportsLegendInnerGap) {
                    Circle().fill(Night.accent(id)).frame(width: UIMetrics.reportsLegendDot, height: UIMetrics.reportsLegendDot)
                    Text(verbatim: id.buddy)
                }
            }
            Text(verbatim: Copywriter.reportsStreakLegend)
        }
        .font(Typography.tracker(UIMetrics.reportsWeekdayFont, .semibold))
        .foregroundStyle(Night.muted)
    }
}

struct OverviewDayCell: View {
    let day: OverviewDay

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.reportsOverviewCellRadius, style: .continuous)
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "\(day.day)")
                .font(Typography.tracker(UIMetrics.reportsMonthFont, day.isFuture ? .semibold : .heavy))
                .foregroundStyle(day.isFuture ? Night.faint : Night.text)
            Spacer(minLength: 0)
            if !day.isFuture {
                HStack(spacing: UIMetrics.reportsDotGap) {
                    ForEach(day.dots) { dot in
                        Circle()
                            .fill(dot.isMet ? Night.accent(dot.habit) : Night.fieldBorder)
                            .frame(width: UIMetrics.reportsDotSize, height: UIMetrics.reportsDotSize)
                    }
                }
            }
        }
        .padding(UIMetrics.reportsOverviewCellPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: UIMetrics.reportsOverviewCellHeight)
        .background(shape.fill(fill))
        .overlay(shape.strokeBorder(border, lineWidth: day.isToday ? UIMetrics.reportsTodayLine : UIMetrics.reportsCellLine))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(day.isStreakDay ? Copywriter.reportsStreakDayLabel(day.day) : "\(day.day)")
    }

    private var fill: Color {
        if day.isFuture { return .clear }
        return day.isStreakDay ? Night.sprout.opacity(UIMetrics.reportsStreakTint) : Night.trackerInset
    }

    private var border: Color {
        if day.isToday { return Night.text }
        if day.isFuture { return Night.divider }
        return day.isStreakDay ? Night.sprout : .clear
    }
}
