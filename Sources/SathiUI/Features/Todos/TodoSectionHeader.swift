import SathiCore
import SwiftUI

struct TodoSectionHeader: View {
    let list: TodoList
    let count: Int

    static let nameColor = Night.todoSectionName
    static let ruleColor = Night.divider

    var body: some View {
        HStack(spacing: UIMetrics.todoSectionSpacing) {
            Circle()
                .fill(Night.todoSoftDot(Night.todoList(list.colorHex)))
                .frame(width: UIMetrics.todoSectionDot, height: UIMetrics.todoSectionDot)
                .accessibilityIdentifier("todos.section.dot." + list.id)
            Text(verbatim: list.name)
                .font(Typography.tracker(UIMetrics.todoSectionFont, .bold))
                .foregroundStyle(Self.nameColor)
                .lineLimit(1)
            Text(verbatim: "\(count)")
                .font(Typography.tracker(UIMetrics.todoSectionCountFont, .semibold))
                .foregroundStyle(Night.faint)
                .accessibilityIdentifier("todos.section.count." + list.id)
            Rectangle()
                .fill(Self.ruleColor)
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
