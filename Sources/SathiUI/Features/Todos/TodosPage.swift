import SathiCore
import SwiftUI

struct TodosPage: View {
    @State private var selection: TodoSelection
    @EnvironmentObject var e: Engine

    init(selection: TodoSelection = .smart(.today)) {
        _selection = State(initialValue: selection)
    }

    var body: some View {
        Group {
            if e.todoAccess == .allowed {
                HStack(spacing: 0) {
                    TodoSideColumn(selection: $selection)
                    TodoItemsColumn(selection: shown).id(shown)
                }
            } else {
                TodoAccessGate()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { e.refreshTodos() }
    }

    private var shown: TodoSelection {
        if case let .list(id) = selection, !e.todoSnapshot.lists.contains(where: { $0.id == id }) {
            return .smart(.today)
        }
        return selection
    }
}
