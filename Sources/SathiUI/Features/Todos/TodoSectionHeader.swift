import SathiCore
import SwiftUI

struct TodoSectionHeader: View {
    let list: TodoList
    let count: Int

    var body: some View {
        let color = Night.todoList(list.colorHex)
        HStack(spacing: UIMetrics.todoSectionSpacing) {
            Circle()
                .fill(color)
                .frame(width: UIMetrics.todoSectionDot, height: UIMetrics.todoSectionDot)
                .accessibilityIdentifier("todos.section.dot." + list.id)
            Text(verbatim: list.name)
                .font(Typography.tracker(UIMetrics.todoSectionFont, .heavy))
                .foregroundStyle(color)
                .lineLimit(1)
            Text(verbatim: "\(count)")
                .font(Typography.tracker(UIMetrics.todoSectionCountFont, .bold))
                .foregroundStyle(Night.muted)
                .accessibilityIdentifier("todos.section.count." + list.id)
            Rectangle()
                .fill(Night.todoSectionRule(color))
                .frame(maxWidth: .infinity)
                .frame(height: UIMetrics.dividerHeight)
                .accessibilityIdentifier("todos.section.rule." + list.id)
        }
        .padding(UIMetrics.todoSectionPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.section." + list.id)
    }
}
