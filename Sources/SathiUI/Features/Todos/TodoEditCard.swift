import SathiCore
import SwiftUI

struct TodoEditCard: View {
    let todo: Todo
    let onClose: () -> Void
    @State private var edited: TodoEditForm?
    @State private var confirmingDelete: Bool
    @State private var failure: String?
    @EnvironmentObject var e: Engine

    init(
        todo: Todo,
        form: TodoEditForm? = nil,
        confirmingDelete: Bool = false,
        failure: String? = nil,
        onClose: @escaping () -> Void
    ) {
        self.todo = todo
        self.onClose = onClose
        _edited = State(initialValue: form)
        _confirmingDelete = State(initialValue: confirmingDelete)
        _failure = State(initialValue: failure)
    }

    private var form: TodoEditForm { edited ?? TodoEditForm(todo: todo, calendar: e.calendar) }

    private func field<V>(_ path: WritableKeyPath<TodoEditForm, V>) -> Binding<V> {
        Binding(get: { form[keyPath: path] }, set: { v in
            var f = form
            f[keyPath: path] = v
            edited = f
        })
    }

    private var hasDate: Binding<Bool> {
        Binding(get: { form.hasDate }, set: { on in
            var f = form
            if on, !f.hasDate, todo.due == nil { f.date = e.calendar.startOfDay(for: e.now) }
            f.hasDate = on
            edited = f
        })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.todoEditSpacing) {
            HStack(spacing: UIMetrics.todoRowSpacing) {
                TodoTick(isDone: todo.isDone, canEdit: false) {}
                TextField(Copywriter.todoNewPlaceholder, text: field(\.title))
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
                TextField(Copywriter.todoNotes, text: field(\.notes), axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(Typography.tracker(UIMetrics.todoFieldFont, .medium))
                    .foregroundStyle(Night.muted)
                    .accessibilityIdentifier("todos.edit.notes")
                    .disabled(!canEdit)
                TodoEditDue(hasDate: hasDate, date: field(\.date), minutes: field(\.minutes))
                    .disabled(!canEdit)
                readOnlyFacts
                TodoEditListChips(lists: e.todoOrderedLists.filter(\.canEdit), selection: field(\.listID))
                    .disabled(!canEdit)
                if let failure {
                    Text(verbatim: failure)
                        .font(Typography.hint)
                        .foregroundStyle(Night.tracker)
                }
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
            switch await engine.saveTodo(t, f) {
            case .saved: close()
            case .partlySaved:
                edited = nil
                failure = Copywriter.todoMoveFailed
            case .failed: failure = Copywriter.todoSaveFailed
            }
        }
    }

    private func delete() {
        let engine = e
        let id = todo.id
        let close = onClose
        Task {
            if case .done = await engine.deleteTodo(id) { close() } else { failure = Copywriter.todoDeleteFailed }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.todoEditRadius, style: .continuous)
    }
}
