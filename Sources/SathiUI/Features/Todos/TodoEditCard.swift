import SathiCore
import SwiftUI

struct TodoEditCard: View {
    let todo: Todo
    let onClose: () -> Void
    @State private var form: TodoEditForm
    @State private var confirmingDelete: Bool
    @EnvironmentObject var e: Engine

    init(todo: Todo, form: TodoEditForm? = nil, confirmingDelete: Bool = false, onClose: @escaping () -> Void) {
        self.todo = todo
        self.onClose = onClose
        _form = State(initialValue: form ?? TodoEditForm(todo: todo, calendar: .current))
        _confirmingDelete = State(initialValue: confirmingDelete)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todoEditSpacing) {
            HStack(spacing: UIMetrics.todoRowSpacing) {
                TodoTick(isDone: todo.isDone, canEdit: false) {}
                TextField(Copywriter.todoNewPlaceholder, text: $form.title)
                    .textFieldStyle(.plain)
                    .font(Typography.tracker(UIMetrics.todoRowTitleFont, .semibold))
                    .foregroundStyle(Night.text)
                    .accessibilityIdentifier("todos.edit.title")
                    .disabled(!canEdit)
                Text(verbatim: Copywriter.todoEditing)
                    .font(Typography.tracker(UIMetrics.todoRowMetaFont, .medium))
                    .foregroundStyle(Night.label)
            }
            VStack(alignment: .leading, spacing: UIMetrics.todoEditSpacing) {
                TextField(Copywriter.todoNotes, text: $form.notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Typography.tracker(UIMetrics.todoFieldFont, .medium))
                    .foregroundStyle(Night.muted)
                    .accessibilityIdentifier("todos.edit.notes")
                    .disabled(!canEdit)
                TodoEditDue(form: $form, today: e.calendar.startOfDay(for: e.now), hadDue: todo.due != nil)
                    .disabled(!canEdit)
                readOnlyFacts
                TodoEditListChips(lists: e.todoSnapshot.lists.filter(\.canEdit), selection: $form.listID)
                    .disabled(!canEdit)
                buttons
            }
            .padding(.leading, UIMetrics.todoEditIndent)
        }
        .padding(UIMetrics.todoEditPadding)
        .background(shape.fill(Night.todoField))
        .overlay(shape.strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.todoBorder))
        .padding(.vertical, UIMetrics.todoRowTextSpacing)
    }

    private var canEdit: Bool {
        e.todoSnapshot.lists.first { $0.id == todo.listID }?.canEdit ?? false
    }

    @ViewBuilder private var readOnlyFacts: some View {
        let priority = Copywriter.todoPriorityText(todo.priority)
        if todo.repeats || priority != nil {
            HStack(spacing: UIMetrics.todoChipSpacing) {
                if todo.repeats { Text(verbatim: Copywriter.todoRepeats) }
                if let priority { Text(verbatim: priority) }
            }
            .font(Typography.tracker(UIMetrics.todoRowMetaFont, .semibold))
            .foregroundStyle(Night.muted)
        }
    }

    private var buttons: some View {
        HStack(spacing: UIMetrics.todoChipSpacing) {
            if confirmingDelete {
                Text(verbatim: Copywriter.todoDeleteConfirm(todo.title))
                    .font(Typography.hint)
                    .foregroundStyle(Night.text)
                Spacer(minLength: 0)
                button(Copywriter.todoKeep, "todos.edit.keep", Night.muted) { confirmingDelete = false }
                button(Copywriter.todoDelete, "todos.edit.confirmDelete", Night.tracker, action: delete)
            } else {
                if canEdit {
                    button(Copywriter.todoDelete, "todos.edit.delete", Night.tracker) { confirmingDelete = true }
                }
                Spacer(minLength: 0)
                button(Copywriter.todoCancel, "todos.edit.cancel", Night.muted, action: onClose)
                if canEdit {
                    button(Copywriter.todoSave, "todos.edit.save", Night.todo, action: save)
                        .disabled(!form.isValid)
                }
            }
        }
    }

    private func button(_ title: String, _ id: String, _ accent: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title).accessibilityIdentifier(id)
        }
        .buttonStyle(GhostButton(accent: accent))
    }

    private func save() {
        let engine = e
        let t = todo
        let f = form
        let close = onClose
        Task {
            if case .done = await engine.saveTodo(t, f) { close() }
        }
    }

    private func delete() {
        let engine = e
        let id = todo.id
        let close = onClose
        Task {
            if case .done = await engine.deleteTodo(id) { close() }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.todoEditRadius, style: .continuous)
    }
}
