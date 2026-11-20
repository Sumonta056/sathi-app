import SathiCore
import SwiftUI

struct TodoBoard: View {
    let sections: [TodoListSection]
    @Binding var editingID: String?
    @Binding var reorder: TodoReorder
    let onAdd: (String) -> Void
    @State private var width: Double?

    var body: some View {
        TodoBoardLayout(columns: columns, gap: UIMetrics.todoBoardGap) {
            ForEach(sections, id: \.list.id) { section in
                TodoBoardCard(
                    section: section,
                    editingID: $editingID,
                    reorder: $reorder,
                    onAdd: section.list.canEdit ? { onAdd(section.list.id) } : nil
                )
                .layoutValue(key: TodoBoardKey.self, value: section.list.id)
                .zIndex(holdsDrag(section) ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .opacity(width == nil ? 0 : 1)
        .background(GeometryReader { g in
            Color.clear.preference(key: TodoBoardWidthKey.self, value: Double(g.size.width))
        })
        .onPreferenceChange(TodoBoardWidthKey.self) { width = $0 }
        .padding(.top, UIMetrics.todoBoardTopPadding)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todos.board")
    }

    private var columns: Int {
        TodoBoardColumns.count(width: width, min: UIMetrics.todoBoardMinWidth, gap: UIMetrics.todoBoardGap)
    }

    private func holdsDrag(_ section: TodoListSection) -> Bool {
        guard let id = reorder.id else { return false }
        return section.todos.contains { $0.id == id }
    }
}

struct TodoBoardWidthKey: PreferenceKey {
    static let defaultValue: Double? = nil

    static func reduce(value: inout Double?, nextValue: () -> Double?) {
        value = nextValue() ?? value
    }
}
