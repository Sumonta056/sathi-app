import SathiCore
import SwiftUI

struct CalendarTodoChip: View {
    let block: CalendarBlock
    let showsTick: Bool
    @State private var editing = false
    @EnvironmentObject var e: Engine

    init(block: CalendarBlock, showsTick: Bool = true) {
        self.block = block
        self.showsTick = showsTick
    }

    private var look: CalendarBlockLook { CalendarBlockLook.of(block.style, categories: []) }

    private var todoID: String {
        if case let .todo(id) = block.source { return id }
        return block.id
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.calendarChipRadius, style: .continuous)
        HStack(spacing: UIMetrics.calendarTodoTickGap) {
            if showsTick { tick }
            Button { editing = true } label: {
                HStack(spacing: 0) {
                    Text(verbatim: block.title)
                        .font(Typography.tracker(UIMetrics.calendarChipFont, .semibold))
                        .foregroundStyle(look.text)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("calendar.todo.open." + todoID)
            .popover(isPresented: $editing, arrowEdge: .trailing) {
                CalendarTodoPopover(todoID: todoID) { editing = false }
                    .environmentObject(e)
            }
        }
        .padding(UIMetrics.calendarChipPadding)
        .frame(maxWidth: .infinity, minHeight: UIMetrics.calendarChipHeight, maxHeight: UIMetrics.calendarChipHeight, alignment: .leading)
        .background(shape.fill(look.fill))
        .overlay(shape.strokeBorder(look.stroke ?? .clear, lineWidth: UIMetrics.cardBorder))
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
