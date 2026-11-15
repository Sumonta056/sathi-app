import SathiCore
import SwiftUI

struct TodoAddField: View {
    let listID: String
    @State private var title: String
    @EnvironmentObject var e: Engine

    init(listID: String, title: String = "") {
        self.listID = listID
        _title = State(initialValue: title)
    }

    var body: some View {
        HStack(spacing: UIMetrics.todoRowSpacing) {
            Image(systemName: "plus")
                .font(.system(size: UIMetrics.todoAddIcon, weight: .bold))
                .foregroundStyle(Night.spark)
            TextField(Copywriter.todoNewPlaceholder, text: $title)
                .textFieldStyle(.plain)
                .font(Typography.tracker(UIMetrics.todoFieldFont, .medium))
                .foregroundStyle(Night.text)
                .onSubmit(add)
                .accessibilityIdentifier("todos.add.field")
            Text(verbatim: Copywriter.todoReturnToAdd)
                .font(Typography.tracker(UIMetrics.todoRowMetaFont, .medium))
                .foregroundStyle(Night.label)
            Button(action: add) {
                Text(verbatim: Copywriter.todoAdd).accessibilityIdentifier("todos.add.button")
            }
            .buttonStyle(GhostButton(accent: Night.todo))
            .disabled(isBlank)
        }
        .padding(UIMetrics.todoAddPadding)
        .background(shape.fill(Night.todoField))
        .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.todoBorder))
    }

    private var isBlank: Bool { title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func add() {
        guard !isBlank else { return }
        let engine = e
        let draft = TodoDraft(listID: listID, title: title, notes: "", due: nil)
        title = ""
        Task { await engine.addTodo(draft) }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.todoAddRadius, style: .continuous)
    }
}
