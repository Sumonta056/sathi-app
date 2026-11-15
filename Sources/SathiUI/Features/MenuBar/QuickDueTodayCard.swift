import SathiCore
import SwiftUI

struct QuickDueTodayCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        Group {
            if let q = e.quickTodos { card(q) }
        }
        .onAppear { e.refreshTodos() }
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
            Button { e.doneTodo(r.todo.id) } label: {
                Circle()
                    .strokeBorder(color, lineWidth: UIMetrics.todoTickBorder)
                    .frame(width: UIMetrics.promptTodoTick, height: UIMetrics.promptTodoTick)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: Copywriter.todoMarkDone))
            .accessibilityIdentifier("quick.todo.\(r.todo.id)")
            Text(verbatim: r.todo.title)
                .font(Typography.hint)
                .foregroundStyle(Night.text)
                .lineLimit(1)
            Spacer(minLength: 0)
            time(r, color)
        }
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
