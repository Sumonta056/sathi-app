import SathiCore
import SwiftUI

struct TodoEditListChips: View {
    let lists: [TodoList]
    @Binding var selection: String

    var body: some View {
        HStack(spacing: UIMetrics.todoChipSpacing) {
            Text(verbatim: Copywriter.todoList)
                .font(Typography.tracker(UIMetrics.todoRowMetaFont, .medium))
                .foregroundStyle(Night.label)
                .frame(width: UIMetrics.todoEditLabelWidth, alignment: .leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIMetrics.todoChipSpacing) {
                    ForEach(lists, id: \.id) { chip($0) }
                }
            }
        }
    }

    private func chip(_ list: TodoList) -> some View {
        let on = list.id == selection
        let shape = RoundedRectangle(cornerRadius: UIMetrics.todoChipRadius, style: .continuous)
        return Button { selection = list.id } label: {
            HStack(spacing: UIMetrics.todoChipSpacing) {
                Circle().fill(Night.todoList(list.colorHex)).frame(width: UIMetrics.todoChipDot, height: UIMetrics.todoChipDot)
                Text(verbatim: list.name)
            }
            .font(Typography.tracker(UIMetrics.todoRowMetaFont, on ? .bold : .medium))
            .foregroundStyle(on ? Night.text : Night.chipText)
            .padding(UIMetrics.todoChipPadding)
            .background(shape.fill(on ? Night.todoFill : .clear))
            .overlay(shape.strokeBorder(on ? Night.todo : Night.fieldBorder, lineWidth: UIMetrics.todoBorder))
            .contentShape(shape)
            .accessibilityIdentifier("todos.edit.list.\(list.id)")
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
