import SathiCore
import SwiftUI

struct TodoAccessStatus: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        switch engine.todoAccess {
        case .allowed:
            HStack(spacing: UIMetrics.blockStatusSpacing) {
                Image(systemName: "checkmark")
                    .font(.system(size: UIMetrics.blockStatusIcon, weight: .heavy))
                Text(verbatim: Copywriter.todosSettingsAllowed)
            }
            .font(Typography.chip)
            .foregroundStyle(Night.sprout)
            .accessibilityIdentifier("settings.todos.access.allowed")
        case .denied:
            status(Copywriter.todosSettingsDenied) {
                Button { engine.openTodoSettings() } label: { Text(verbatim: Copywriter.todoOpenSettings) }
                    .accessibilityIdentifier("settings.todos.access.open")
            }
        case .notAsked:
            status(Copywriter.todosSettingsNotAsked) {
                Button { Task { await engine.requestTodoAccess() } } label: { Text(verbatim: Copywriter.todoAllowAccess) }
                    .accessibilityIdentifier("settings.todos.access.allow")
            }
        }
    }

    private func status(_ text: String, @ViewBuilder button: () -> some View) -> some View {
        HStack(spacing: UIMetrics.sectionSpacing) {
            Text(verbatim: text)
                .font(Typography.chip)
                .foregroundStyle(Night.muted)
            button()
                .buttonStyle(GhostButton(accent: Night.todo, height: UIMetrics.blockActionHeight))
        }
    }
}
