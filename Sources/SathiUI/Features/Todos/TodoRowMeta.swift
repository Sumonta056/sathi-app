import SathiCore
import SwiftUI

struct TodoRowMeta: View {
    let todo: Todo
    var below = false
    @Environment(\.mainLayout) private var layout
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(spacing: below ? UIMetrics.todoBoardMetaSpacing : UIMetrics.todoChipSpacing) {
            if todo.repeats {
                HStack(spacing: below ? UIMetrics.todoBoardMetaIconSpacing : UIMetrics.todoMetaIconSpacing) {
                    Image(systemName: "repeat")
                    if below || Self.showsRepeatsWord(layout) { Text(verbatim: Copywriter.todoRepeats) }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(verbatim: Copywriter.todoRepeats))
                .foregroundStyle(Night.muted)
            }
            if below && todo.repeats && todo.due != nil {
                Text(verbatim: Copywriter.todoBoardMetaSeparator)
                    .foregroundStyle(Night.muted)
                    .accessibilityIdentifier("todos.row.meta.sep.\(todo.id)")
            }
            if let due = todo.due {
                Text(verbatim: Copywriter.todoDueText(due, now: e.now, calendar: e.calendar))
                    .foregroundStyle(dueColor)
                    .frame(minWidth: below ? nil : UIMetrics.todoRowDueMinWidth, alignment: below ? .leading : .trailing)
                    .accessibilityIdentifier("todos.row.due.\(todo.id)")
            }
        }
        .font(Typography.tracker(UIMetrics.todoRowMetaFont, .semibold))
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(below ? "todos.row.meta.below.\(todo.id)" : "todos.row.meta.\(todo.id)")
    }

    static func showsRepeatsWord(_ layout: MainLayout) -> Bool { !layout.isNarrow }

    private var dueColor: Color {
        if TodoRules.isOverdue(todo, now: e.now, calendar: e.calendar) { return Night.todoOverdue }
        if TodoRules.isDueToday(todo, now: e.now, calendar: e.calendar) { return Night.todoDueToday }
        return Night.muted
    }
}
