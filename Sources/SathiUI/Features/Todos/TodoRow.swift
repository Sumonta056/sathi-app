import SathiCore
import SwiftUI

struct TodoRow: View {
    let todo: Todo
    let canEdit: Bool
    let onSelect: () -> Void
    @EnvironmentObject var e: Engine

    init(todo: Todo, canEdit: Bool, onSelect: @escaping () -> Void) {
        self.todo = todo
        self.canEdit = canEdit
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.todoRowSpacing) {
            TodoTick(isDone: todo.isDone, canEdit: canEdit) {
                let engine = e
                let id = todo.id
                let done = !todo.isDone
                Task { await engine.setTodoDone(id, done) }
            }
            Button(action: onSelect) {
                VStack(alignment: .leading, spacing: UIMetrics.todoRowTextSpacing) {
                    Text(verbatim: todo.title)
                        .font(Typography.tracker(UIMetrics.todoRowTitleFont, .medium))
                        .foregroundStyle(todo.isDone ? Night.muted : Night.text)
                        .strikethrough(todo.isDone)
                    meta
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityIdentifier("todos.row.\(todo.id)")
            }
            .buttonStyle(.plain)
        }
        .padding(UIMetrics.todoRowPadding)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Night.todoRowLine).frame(height: UIMetrics.dividerHeight)
        }
    }

    @ViewBuilder private var meta: some View {
        if todo.due != nil || todo.repeats {
            HStack(spacing: UIMetrics.todoChipSpacing) {
                if let due = todo.due {
                    HStack(spacing: 0) {
                        Text(verbatim: Copywriter.todoDueText(due, now: e.now, calendar: e.calendar))
                            .foregroundStyle(dueColor)
                    }
                    .accessibilityIdentifier("todos.row.due.\(todo.id)")
                }
                if todo.repeats {
                    Text(verbatim: Copywriter.todoRepeats).foregroundStyle(Night.muted)
                }
            }
            .font(Typography.tracker(UIMetrics.todoRowMetaFont, .semibold))
        }
    }

    private var dueColor: Color {
        if TodoRules.isOverdue(todo, now: e.now, calendar: e.calendar) { return Night.todoOverdue }
        if TodoRules.isDueToday(todo, now: e.now, calendar: e.calendar) { return Night.todoDueToday }
        return Night.muted
    }
}
