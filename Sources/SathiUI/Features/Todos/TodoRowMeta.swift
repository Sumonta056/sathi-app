import SathiCore
import SwiftUI

struct TodoRowMeta: View {
    let todo: Todo
    @Environment(\.mainLayout) private var layout
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(spacing: UIMetrics.todoChipSpacing) {
            if todo.repeats {
                HStack(spacing: UIMetrics.todoMetaIconSpacing) {
                    Image(systemName: "repeat")
                    if Self.showsRepeatsWord(layout) { Text(verbatim: Copywriter.todoRepeats) }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text(verbatim: Copywriter.todoRepeats))
                .foregroundStyle(Night.muted)
            }
            if let due = todo.due {
                Text(verbatim: Copywriter.todoDueText(due, now: e.now, calendar: e.calendar))
                    .foregroundStyle(dueColor)
                    .frame(minWidth: UIMetrics.todoRowDueMinWidth, alignment: .trailing)
                    .accessibilityIdentifier("todos.row.due.\(todo.id)")
            }
        }
        .font(Typography.tracker(UIMetrics.todoRowMetaFont, .semibold))
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.row.meta.\(todo.id)")
    }

    static func showsRepeatsWord(_ layout: MainLayout) -> Bool { !layout.isNarrow }

    private var dueColor: Color {
        if TodoRules.isOverdue(todo, now: e.now, calendar: e.calendar) { return Night.todoOverdue }
        if TodoRules.isDueToday(todo, now: e.now, calendar: e.calendar) { return Night.todoDueToday }
        return Night.muted
    }
}
