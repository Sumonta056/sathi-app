import SathiCore
import SwiftUI

struct StreakCalendarView: View {
    static let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

    let month: StreakMonth

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            HStack {
                Text(verbatim: month.title)
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.text)
                Spacer(minLength: 0)
                Label {
                    Text(verbatim: month.streakText)
                } icon: {
                    Image(systemName: "leaf.fill")
                }
                .font(Typography.hint)
                .foregroundStyle(Night.sprout)
            }
            LazyVGrid(columns: columns, spacing: UIMetrics.calendarCellGap) {
                ForEach(Self.slots(month)) { slot in
                    switch slot {
                    case let .weekday(i):
                        Text(verbatim: Self.weekdays[i])
                            .font(Typography.badge)
                            .foregroundStyle(Night.faint)
                    case .blank:
                        Color.clear.aspectRatio(1, contentMode: .fit)
                    case let .day(cell):
                        StreakCellView(cell: cell)
                    }
                }
            }
        }
    }

    static func slots(_ month: StreakMonth) -> [CalendarSlot] {
        weekdays.indices.map(CalendarSlot.weekday)
            + (0 ..< month.leadingBlanks).map(CalendarSlot.blank)
            + month.cells.map(CalendarSlot.day)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: UIMetrics.calendarCellGap), count: Self.weekdays.count)
    }
}

struct StreakCellView: View {
    let cell: StreakCell

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarCellRadius, style: .continuous)
        shape
            .fill(fill)
            .aspectRatio(1, contentMode: .fit)
            .overlay(shape.strokeBorder(cell.isToday ? Night.text : .clear, lineWidth: UIMetrics.calendarTodayLine))
            .accessibilityLabel("\(cell.day)")
    }

    private var fill: Color {
        let levels = UIMetrics.streakLevelOpacity
        guard cell.level > 0, cell.level <= levels.count else { return Night.divider }
        return Night.sprout.opacity(levels[cell.level - 1])
    }
}
