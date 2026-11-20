import SathiCore
import SwiftUI

struct QuickDueTodayCard: View {
    @EnvironmentObject var e: Engine
    @EnvironmentObject var finishing: TodoFinishing
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let q = e.quickTodos { card(q) }
    }

    private func card(_ q: QuickTodos) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.todoQuickGap) {
            HStack(spacing: UIMetrics.quickActionSpacing) {
                Text(verbatim: Copywriter.todoDueToday)
                    .font(Typography.rowLabel)
                    .foregroundStyle(Night.todoDueAccent)
                Spacer(minLength: 0)
                if q.overdue > 0 { badge(Copywriter.todoQuickOverdue(q.overdue), Night.todoOverdue) }
                badge(Copywriter.todoQuickCount(q.count), Night.todoDueAccent)
            }
            ForEach(q.rows, id: \.todo.id) { row($0) }
        }
        .padding(UIMetrics.todoQuickPadding)
        .background(shape.fill(Night.todoDueAccent.opacity(UIMetrics.chipFillOpacity)))
        .overlay(shape.strokeBorder(Night.todoDueAccent.opacity(UIMetrics.todoLineOpacity), lineWidth: UIMetrics.cardBorder))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quick.todos")
    }

    private func row(_ r: QuickTodoRow) -> some View {
        let color = r.isOverdue ? Night.todoOverdue : Night.todoDueAccent
        return HStack(spacing: UIMetrics.todoQuickGap) {
            TodoTick(
                isDone: false,
                canEdit: true,
                size: UIMetrics.promptTodoTick,
                color: color,
                idleColor: color,
                reduceMotion: reduceMotion,
                phase: finishing.phase(r.todo.id)
            ) { finishing.tick(r.todo.id) }
                .accessibilityIdentifier("quick.todo.\(r.todo.id)")
            Text(verbatim: r.todo.title)
                .font(Typography.hint)
                .foregroundStyle(finishing.phase(r.todo.id) == nil ? Night.text : Night.muted)
                .lineLimit(1)
                .overlay { if finishing.phase(r.todo.id) != nil { TodoStrike(reduceMotion: reduceMotion) } }
            Spacer(minLength: 0)
            time(r, color)
        }
        .modifier(TodoFold(leaving: finishing.phase(r.todo.id) == .leaving, reduceMotion: reduceMotion))
    }

    @ViewBuilder private func time(_ r: QuickTodoRow, _ color: Color) -> some View {
        let text = Text(verbatim: r.timeText).font(Typography.hint).foregroundStyle(color)
        if r.isOverdue {
            text.accessibilityIdentifier("quick.todo.late.\(r.todo.id)")
        } else {
            text
        }
    }

    private func badge(_ text: String, _ color: Color) -> some View {
        Text(verbatim: text)
            .font(Typography.hint)
            .foregroundStyle(Night.onAccent)
            .padding(UIMetrics.todoBadgePadding)
            .background(Capsule().fill(color))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
