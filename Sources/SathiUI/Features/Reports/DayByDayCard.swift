import SathiCore
import SwiftUI

struct DayByDayCard: View {
    let overview: ReportsOverview
    let open: (HabitID) -> Void

    var body: some View {
        ReportsCard {
            Text(verbatim: Copywriter.reportsDayByDay)
                .font(Typography.tracker(UIMetrics.reportsCardTitleFont, .heavy))
                .foregroundStyle(Night.text)
            VStack(spacing: UIMetrics.reportsGridGap) {
                HStack(spacing: UIMetrics.reportsGridGap) {
                    Spacer(minLength: 0).frame(width: UIMetrics.reportsGridNameWidth)
                    ForEach(overview.columns) { column in
                        Text(verbatim: column.label)
                            .font(Typography.tracker(UIMetrics.reportsGridFont, column.isToday ? .heavy : .semibold))
                            .foregroundStyle(column.isToday ? Night.text : column.isFuture ? Night.faint : Night.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(UIMetrics.reportsGridMinScale)
                            .frame(maxWidth: .infinity)
                    }
                }
                ForEach(overview.rows) { row in
                    HStack(spacing: UIMetrics.reportsGridGap) {
                        Button { open(row.habit) } label: {
                            Text(verbatim: row.habit.buddy)
                                .font(Typography.tracker(UIMetrics.reportsGridFont, .heavy))
                                .foregroundStyle(Night.accent(row.habit))
                                .frame(width: UIMetrics.reportsGridNameWidth, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        ForEach(row.cells) { cell in
                            DayGridCell(cell: cell, habit: row.habit)
                        }
                    }
                }
            }
            Text(verbatim: Copywriter.reportsDayByDayLegend)
                .font(Typography.tracker(UIMetrics.reportsGridLegendFont, .semibold))
                .foregroundStyle(Night.muted)
        }
    }
}

struct DayGridCell: View {
    let cell: BuddyDayCell
    let habit: HabitID

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.reportsTabRadius, style: .continuous)
        Text(verbatim: cell.text)
            .font(Typography.tracker(UIMetrics.reportsGridFont, cell.state == .met ? .heavy : .semibold))
            .foregroundStyle(textColor)
            .lineLimit(1)
            .minimumScaleFactor(UIMetrics.reportsGridMinScale)
            .frame(maxWidth: .infinity)
            .frame(height: UIMetrics.reportsGridCellHeight)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(
                cell.state == .future ? Night.border : .clear,
                style: StrokeStyle(lineWidth: UIMetrics.reportsDashedLine, dash: UIMetrics.reportsDash)
            ))
    }

    private var fill: Color {
        switch cell.state {
        case .met: Night.accent(habit)
        case .some, .off: Night.heroFill(habit)
        case .none: Night.divider
        case .future: .clear
        }
    }

    private var textColor: Color {
        switch cell.state {
        case .met: Night.onAccent
        case .some, .off: Night.accent(habit)
        case .none, .future: Night.muted
        }
    }
}
