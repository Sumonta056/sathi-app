import SathiCore
import SwiftUI

struct TodoListRow: View {
    let list: TodoList
    let count: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: UIMetrics.todoListRowSpacing) {
                Circle().fill(Night.todoList(list.colorHex)).frame(width: UIMetrics.todoListDot, height: UIMetrics.todoListDot)
                Text(verbatim: list.name)
                    .font(Typography.tracker(UIMetrics.todoListFont, isSelected ? .semibold : .medium))
                    .foregroundStyle(Night.text)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(verbatim: "\(count)")
                    .font(Typography.tracker(UIMetrics.todoListFont, .medium))
                    .foregroundStyle(Night.label)
            }
            .padding(UIMetrics.todoListRowPadding)
            .background(RoundedRectangle(cornerRadius: UIMetrics.todoListRadius, style: .continuous).fill(isSelected ? Night.navSelected : .clear))
            .contentShape(Rectangle())
            .accessibilityIdentifier("todos.list.\(list.id)")
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .contextMenu {
            if list.canEdit {
                Button(Copywriter.todoRenameList, action: onRename)
            }
        }
    }
}
