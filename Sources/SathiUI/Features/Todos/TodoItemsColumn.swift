import SathiCore
import SwiftUI

struct TodoItemsColumn: View {
    let selection: TodoSelection
    @State private var showCompleted: Bool
    @State private var editingID: String?
    @EnvironmentObject var e: Engine

    init(selection: TodoSelection, showCompleted: Bool = false) {
        self.selection = selection
        _showCompleted = State(initialValue: showCompleted)
    }

    var body: some View {
        let page = e.todoPage(selection)
        let rows = showCompleted ? page.open + page.completed : page.open
        VStack(alignment: .leading, spacing: UIMetrics.todoItemsSpacing) {
            header(page)
            if !page.completed.isEmpty { toggle(page.completed.count) }
            if let target = page.targetListID {
                TodoAddField(listID: target).id(target)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if rows.isEmpty {
                        Text(verbatim: Copywriter.todoEmptyList)
                            .font(Typography.hint)
                            .foregroundStyle(Night.faint)
                            .padding(UIMetrics.todoRowPadding)
                    }
                    ForEach(rows, id: \.id) { item($0) }
                }
            }
        }
        .padding(UIMetrics.todoItemsPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private func item(_ todo: Todo) -> some View {
        if editingID == todo.id {
            TodoEditCard(todo: todo) { editingID = nil }
        } else {
            TodoRow(todo: todo, canEdit: canEdit(todo)) { editingID = todo.id }
        }
    }

    private func header(_ page: TodoPageModel) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: page.title)
            Spacer(minLength: 0)
            Text(verbatim: "\(page.open.count)")
        }
        .font(Typography.tracker(UIMetrics.todoTitleFont, .heavy))
        .foregroundStyle(accent)
        .lineLimit(1)
    }

    private func toggle(_ count: Int) -> some View {
        Button { showCompleted.toggle() } label: {
            Text(verbatim: showCompleted ? Copywriter.todoHideCompleted : Copywriter.todoCompletedToggle(count))
                .font(Typography.tracker(UIMetrics.todoToggleFont, .medium))
                .foregroundStyle(Night.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var accent: Color {
        switch selection {
        case let .smart(list): Night.todoTile(list).dot
        case let .list(id): e.todoSnapshot.lists.first { $0.id == id }.map { Night.todoList($0.colorHex) } ?? Night.todo
        }
    }

    private func canEdit(_ todo: Todo) -> Bool {
        e.todoSnapshot.lists.first { $0.id == todo.listID }?.canEdit ?? false
    }
}
