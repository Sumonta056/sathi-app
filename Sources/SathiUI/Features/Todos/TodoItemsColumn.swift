import SathiCore
import SwiftUI

struct TodoItemsColumn: View {
    let selection: TodoSelection
    @State private var showCompleted: Bool
    @State private var editingID: String?
    @State private var addListID: String?
    @State private var addFocus = 0
    @State private var reorder = TodoReorder()
    @State private var frames = TodoRowFrames()
    @Environment(\.mainLayout) private var layout
    @EnvironmentObject var e: Engine

    init(selection: TodoSelection, showCompleted: Bool = false) {
        self.selection = selection
        _showCompleted = State(initialValue: showCompleted)
    }

    var body: some View {
        let page = e.todoPage(selection)
        let rows = showCompleted ? page.open + page.completed : page.open
        VStack(alignment: .leading, spacing: UIMetrics.todoItemsSpacing) {
            TodoItemsHeader(page: page, accent: accent, showCompleted: $showCompleted)
            if let target = Self.addTarget(page, chosen: addListID, board: isBoard) {
                TodoAddField(listID: target, due: page.defaultDue, listName: chosenName(page, target), focusToken: addFocus)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if rows.isEmpty {
                        Text(verbatim: Copywriter.todoEmptyList)
                            .font(Typography.hint)
                            .foregroundStyle(Night.faint)
                            .padding(UIMetrics.todoRowPadding)
                    }
                    if page.sections.isEmpty {
                        ForEach(rows, id: \.id) { item($0, peers: page.open) }
                    } else if isBoard {
                        TodoBoard(sections: page.sections, editingID: $editingID, reorder: $reorder) { id in
                            addListID = id
                            addFocus += 1
                        }
                    } else {
                        ForEach(page.sections, id: \.list.id) { section in
                            TodoSectionHeader(list: section.list, count: section.todos.count)
                            ForEach(section.todos, id: \.id) { item($0, peers: section.todos) }
                        }
                    }
                }
                .coordinateSpace(name: TodoReorderRow.space)
                .onPreferenceChange(TodoRowFramesKey.self) { frames.all = $0 }
            }
        }
        .onChange(of: isBoard) { _ in addListID = nil }
        .padding(Self.padding(layout))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private func item(_ todo: Todo, peers: [Todo]) -> some View {
        if editingID == todo.id {
            TodoEditCard(todo: todo) { editingID = nil }
        } else if Self.canDrag(selection), !todo.isDone {
            TodoRow(todo: todo, canEdit: canEdit(todo)) { editingID = todo.id }
                .todoReorder(todo.id, peers: peers.map(\.id), frames: frames, state: $reorder) { e.moveTodo($0, before: $1) }
        } else {
            TodoRow(todo: todo, canEdit: canEdit(todo)) { editingID = todo.id }
        }
    }

    static func canDrag(_ selection: TodoSelection) -> Bool {
        switch selection {
        case .list, .smart(.all): true
        case .smart: false
        }
    }

    private var isBoard: Bool {
        selection == .smart(.all) && e.data.prefs.todos.allView == .board
    }

    static func addTarget(_ page: TodoPageModel, chosen: String?, board: Bool) -> String? {
        guard page.targetListID != nil else { return nil }
        if board, let chosen, page.sections.contains(where: { $0.list.id == chosen && $0.list.canEdit }) { return chosen }
        return page.targetListID
    }

    private func chosenName(_ page: TodoPageModel, _ target: String) -> String? {
        guard isBoard, addListID == target else { return nil }
        return page.sections.first { $0.list.id == target }?.list.name
    }

    private var accent: Color {
        switch selection {
        case .smart(.all): Night.text
        case let .smart(list): Night.todoTile(list).dot
        case .list: Night.text
        }
    }

    static func padding(_ layout: MainLayout) -> EdgeInsets {
        layout.isNarrow ? UIMetrics.todoItemsPaddingNarrow : UIMetrics.todoItemsPadding
    }

    private func canEdit(_ todo: Todo) -> Bool {
        e.todoSnapshot.lists.first { $0.id == todo.listID }?.canEdit ?? false
    }
}
