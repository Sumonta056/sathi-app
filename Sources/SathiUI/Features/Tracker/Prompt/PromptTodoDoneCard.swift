import SathiCore
import SwiftUI

struct PromptTodoDoneCard: View {
    let ask: PromptMarkDone
    let actions: TrackerPromptActions

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.todoCardRadius, style: .continuous)
        HStack(spacing: UIMetrics.todoQuickGap) {
            Circle()
                .strokeBorder(Night.promptTodo, lineWidth: UIMetrics.todoTickBorder)
                .frame(width: UIMetrics.promptTodoTick, height: UIMetrics.promptTodoTick)
            VStack(alignment: .leading, spacing: UIMetrics.todoRowGap) {
                Text(verbatim: ask.question)
                    .font(Typography.tracker(UIMetrics.promptRunDetailFont, .heavy))
                    .foregroundStyle(Night.text)
                    .lineLimit(2)
                Text(verbatim: Copywriter.todoAsksOnce)
                    .font(Typography.tracker(UIMetrics.promptNoteFont, .medium))
                    .foregroundStyle(Night.promptSecondary)
            }
            Spacer(minLength: 0)
            button(Copywriter.todoNotYet, id: "prompt.notYet", filled: false) { actions.markTodoDone(false) }
            button(Copywriter.todoMarkDone, id: "prompt.markDone", filled: true) { actions.markTodoDone(true) }
        }
        .padding(UIMetrics.todoCardPadding)
        .background(shape.fill(Night.promptTodo.opacity(UIMetrics.todoFillOpacity)))
        .overlay(shape.strokeBorder(Night.promptTodo.opacity(UIMetrics.todoLineOpacity), lineWidth: UIMetrics.promptBorder))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("prompt.todoDoneCard")
    }

    private func button(_ label: String, id: String, filled: Bool, action: @escaping @MainActor () -> Void) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.todoCardButtonRadius, style: .continuous)
        return Button(action: action) {
            Text(verbatim: label)
                .font(Typography.tracker(UIMetrics.promptButtonFont, filled ? .heavy : .semibold))
                .foregroundStyle(filled ? Night.onAccent : Night.chipText)
                .lineLimit(1)
                .padding(.horizontal, UIMetrics.todoCardButtonPadding)
                .frame(height: UIMetrics.todoCardButtonHeight)
                .background(shape.fill(filled ? Night.promptTodo : Color.clear))
                .overlay(shape.strokeBorder(filled ? Color.clear : Night.promptBoxLine, lineWidth: UIMetrics.promptBorder))
                .contentShape(shape)
                .accessibilityIdentifier(id)
        }
        .buttonStyle(TrackerPressStyle())
        .fixedSize()
    }
}
