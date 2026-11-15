import SathiCore
import SwiftUI

struct TodoDueDateChip: View {
    @Binding var date: Date
    @State private var isOpen = false
    @State private var offset = 0
    @EnvironmentObject var e: Engine

    var body: some View {
        Button {
            offset = 0
            isOpen.toggle()
        } label: {
            Text(verbatim: label)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .fixedSize()
                .padding(UIMetrics.timeButtonPadding)
                .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
                .overlay(
                    RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                        .strokeBorder(TimeMenu.border(isOpen: isOpen, active: true, accent: Night.todo), lineWidth: UIMetrics.chipBorder)
                )
                .contentShape(Rectangle())
                .accessibilityIdentifier("todos.edit.date")
        }
        .buttonStyle(.plain)
        .fixedSize()
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            TodoDueCalendar(date: $date, offset: $offset) { isOpen = false }
                .environmentObject(e)
        }
    }

    private var label: String {
        Copywriter.calendarEventDate(DayKey(date, calendar: Calendar.gregorian(in: e.calendar.timeZone)), calendar: e.calendar)
    }
}

struct TodoDueCalendar: View {
    @Binding var date: Date
    @Binding var offset: Int
    let onPick: () -> Void
    @EnvironmentObject var e: Engine

    var body: some View {
        MonthDayGrid(
            month: TodoDueMonth.month(selected: date, offset: offset, calendar: e.calendar),
            accent: Night.todo,
            offset: $offset,
            markedValue: Copywriter.todoDueMarked
        ) { key in
            date = key.start(in: Calendar.gregorian(in: e.calendar.timeZone))
            offset = 0
            onPick()
        }
    }
}
