import SathiCore
import SwiftUI

struct TodosSettingsPage: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let prefs = engine.data.prefs.todos
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            SettingsSubtitle(text: Copywriter.todosSettingsSubtitle)
            SettingsCard {
                SettingRow(label: Copywriter.todosSettingsOnLabel, showsDivider: false) {
                    BuddySwitch(isOn: isOn, accent: Night.todo, label: Copywriter.mainPageTodos)
                }
                if prefs.isOn {
                    SettingRow(label: Copywriter.todosSettingsAccess) { TodoAccessStatus() }
                    SettingRow(label: Copywriter.todosSettingsAskWhenDue, hint: Copywriter.todosSettingsAskWhenDueHint) {
                        BuddySwitch(isOn: $e.data.prefs.todos.askWhenDue, accent: Night.todo, label: Copywriter.todosSettingsAskWhenDue)
                    }
                }
            }
            if prefs.isOn, engine.todoAccess == .allowed {
                SectionLabel(Copywriter.todosSettingsShownLists)
                SettingsCard {
                    ForEach(Array(engine.todoAllLists().enumerated()), id: \.element.id) { i, list in
                        SettingRow(label: list.name, hint: list.accountName, showsDivider: i > 0) {
                            BuddySwitch(isOn: shown(list.id), accent: Night.todoList(list.colorHex), label: list.name)
                        }
                    }
                }
            }
        }
        .onAppear { engine.refreshTodos() }
    }

    private var isOn: Binding<Bool> {
        let engine = e
        return Binding(get: { engine.data.prefs.todos.isOn }, set: { on in Task { await engine.setTodosOn(on) } })
    }

    private func shown(_ id: String) -> Binding<Bool> {
        let engine = e
        return Binding(
            get: { !engine.data.prefs.todos.hiddenListIDs.contains(id) },
            set: { engine.setTodoListShown(id, $0) }
        )
    }
}
