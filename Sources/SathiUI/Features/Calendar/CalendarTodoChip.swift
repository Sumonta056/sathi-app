import SathiCore
import SwiftUI

struct CalendarTodoChip: View {
    let block: CalendarBlock
    let showsTick: Bool
    let isPill: Bool
    @State private var editing = false
    @EnvironmentObject var e: Engine

    init(block: CalendarBlock, showsTick: Bool = true, isPill: Bool = false) {
        self.block = block
        self.showsTick = showsTick
        self.isPill = isPill
    }

    private var height: CGFloat { isPill ? UIMetrics.calendarTodoPillHeight : UIMetrics.calendarChipHeight }
    private var font: CGFloat { isPill ? UIMetrics.calendarTodoPillFont : UIMetrics.calendarChipFont }

    private var look: CalendarBlockLook { CalendarBlockLook.of(block.style, categories: []) }

    private var todoID: String {
        if case let .todo(id) = block.source { return id }
        return block.id
    }

    private var due: String? {
        !isPill || block.isAllDay ? nil : Copywriter.trackerClock(block.interval.start, calendar: e.rangeCalendar)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: isPill ? height / 2 : UIMetrics.calendarChipRadius, style: .continuous)
        Button { editing = true } label: {
            HStack(spacing: UIMetrics.calendarTodoTickGap) {
                if showsTick {
                    Color.clear.frame(width: UIMetrics.calendarTodoTickHit, height: UIMetrics.calendarTodoTickHit)
                }
                Text(verbatim: block.title)
                    .font(Typography.tracker(font, .semibold))
                    .foregroundStyle(look.text)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if let due {
                    Text(verbatim: due)
                        .font(Typography.tracker(UIMetrics.calendarTodoTimeFont, .semibold))
                        .foregroundStyle(look.text.opacity(UIMetrics.calendarTimeOpacity))
                        .lineLimit(1)
                        .fixedSize()
                }
            }
            .padding(UIMetrics.calendarChipPadding)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .leading)
            .background(shape.fill(isPill ? Night.card : look.fill))
            .overlay(shape.strokeBorder(look.stroke ?? .clear, lineWidth: UIMetrics.cardBorder))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if showsTick { tick.padding(.leading, UIMetrics.calendarChipPadding.leading) }
        }
        .popover(isPresented: $editing, arrowEdge: .trailing) {
            CalendarTodoPopover(todoID: todoID) { editing = false }
                .environmentObject(e)
        }
        .accessibilityIdentifier("calendar.todo.chip." + todoID)
    }

    private var tick: some View {
        Button { e.completeCalendarTodo(todoID) } label: {
            Circle()
                .strokeBorder(look.stroke ?? Night.faint, lineWidth: UIMetrics.calendarTodoTickRing)
                .frame(width: UIMetrics.calendarTodoTick, height: UIMetrics.calendarTodoTick)
                .frame(width: UIMetrics.calendarTodoTickHit, height: UIMetrics.calendarTodoTickHit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Copywriter.calendarTodoMarkDone)
        .accessibilityIdentifier("calendar.todo.done." + todoID)
    }
}
