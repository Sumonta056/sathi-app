import SathiCore
import SwiftUI

struct TodoSectionHeader: View {
    let list: TodoList

    var body: some View {
        HStack(spacing: UIMetrics.todoChipSpacing) {
            Circle()
                .fill(Night.todoList(list.colorHex))
                .frame(width: UIMetrics.todoChipDot, height: UIMetrics.todoChipDot)
                .accessibilityIdentifier("todos.section.dot." + list.id)
            Text(verbatim: list.name)
                .font(Typography.tracker(UIMetrics.todoSectionFont, .bold))
                .foregroundStyle(Night.text)
                .lineLimit(1)
        }
        .padding(UIMetrics.todoSectionPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.section." + list.id)
    }
}
