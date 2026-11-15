import SathiCore
import SwiftUI

struct BuddyMonthCard: View {
    @EnvironmentObject var e: Engine
    let start: StatsRange
    let habit: HabitID
    @State private var picked: StatsRange?
    @State private var memo = RangeMemo<BuddyMonthRequest, BuddyMonth>()

    var body: some View {
        let month = picked ?? start
        let data = memo.value(BuddyMonthRequest(month: month, habit: habit), range: month, engine: e) {
            $0.buddyMonth($1.month, habit: $1.habit)
        }
        BuddyMonthView(month: data) { step in
            picked = step < 0 ? month.previous : month.next
        }
    }
}

struct BuddyMonthRequest: Equatable {
    let month: StatsRange
    let habit: HabitID
}

struct BuddyMonthView: View {
    let month: BuddyMonth
    var step: (Int) -> Void = { _ in }

    var body: some View {
        ReportsCard {
            MonthHeader(title: month.title, canGoForward: month.canGoForward, step: step) {
                Text(verbatim: month.goalDaysText)
                    .font(Typography.tracker(UIMetrics.reportsMonthFont, .heavy))
                    .foregroundStyle(Night.accent(month.habit))
            }
            MonthGrid(leadingBlanks: month.leadingBlanks, count: month.cells.count) { index in
                BuddyMonthCellView(cell: month.cells[index], habit: month.habit)
            }
        }
        .reportsCalendarWidth()
    }
}

struct BuddyMonthCellView: View {
    let cell: BuddyMonthCell
    let habit: HabitID

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.reportsTabRadius, style: .continuous)
        Text(verbatim: "\(cell.day)")
            .font(Typography.tracker(UIMetrics.reportsWeekdayFont, cell.state == .met ? .heavy : .semibold))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: UIMetrics.reportsBuddyCellHeight)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(border, lineWidth: cell.isToday ? UIMetrics.reportsTodayLine : UIMetrics.reportsCellLine))
    }

    private var fill: Color {
        switch cell.state {
        case .met: Night.accent(habit)
        case .some: Night.heroFill(habit)
        case .none, .off: Night.divider
        case .future: .clear
        }
    }

    private var textColor: Color {
        switch cell.state {
        case .met: Night.onAccent
        case .some: Night.accent(habit)
        case .none, .off: Night.muted
        case .future: Night.faint
        }
    }

    private var border: Color {
        if cell.isToday { return Night.text }
        return cell.state == .future ? Night.divider : .clear
    }
}
