import SathiCore
import SwiftUI

struct PromptTodoPane: View {
    @ObservedObject var model: ActivityPromptModel
    let todos: [PromptTodo]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptPaneGap) {
            Text(verbatim: Copywriter.todoDueNow)
                .font(Typography.tracker(UIMetrics.promptTagFont, .heavy))
                .tracking(UIMetrics.promptTagTracking)
                .foregroundStyle(Night.promptSecondary)
            ForEach(todos, id: \.id) { row($0) }
            Spacer(minLength: 0)
            Text(verbatim: Copywriter.todoPickHint)
                .font(Typography.tracker(UIMetrics.promptNoteFont, .medium))
                .foregroundStyle(Night.promptSecondary)
        }
        .padding(UIMetrics.promptPanePadding)
        .frame(width: UIMetrics.promptPaneWidth, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Night.promptPane)
    }

    private func row(_ todo: PromptTodo) -> some View {
        let on = model.todoID == todo.id
        let shape = RoundedRectangle(cornerRadius: UIMetrics.todoRowRadius, style: .continuous)
        return Button { model.pick(todo: todo) } label: {
            HStack(spacing: UIMetrics.todoQuickGap) {
                Circle()
                    .strokeBorder(on ? Night.promptTodo : Night.promptSecondary, lineWidth: UIMetrics.todoTickBorder)
                    .frame(width: UIMetrics.promptTodoTick, height: UIMetrics.promptTodoTick)
                VStack(alignment: .leading, spacing: UIMetrics.todoRowGap) {
                    Text(verbatim: todo.title)
                        .font(Typography.tracker(UIMetrics.promptRunDetailFont, .heavy))
                        .foregroundStyle(Night.text)
                        .lineLimit(2)
                    Text(verbatim: todo.detail)
                        .font(Typography.tracker(UIMetrics.promptNoteFont, .medium))
                        .foregroundStyle(Night.promptSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(UIMetrics.promptTodoRowPadding)
            .background(shape.fill(on ? Night.promptTodo.opacity(UIMetrics.todoFillOpacity) : Night.promptCard))
            .overlay(shape.strokeBorder(on ? Night.promptTodo : Night.promptCardLine, lineWidth: UIMetrics.promptBorder))
            .contentShape(shape)
            .accessibilityIdentifier("prompt.todo.\(todo.id)")
        }
        .buttonStyle(TrackerPressStyle())
    }
}
