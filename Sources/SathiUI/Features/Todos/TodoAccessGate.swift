import SathiCore
import SwiftUI

struct TodoAccessGate: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        VStack(spacing: UIMetrics.todoFormSpacing) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: UIMetrics.todoGateIcon, weight: .bold))
                .foregroundStyle(Night.todo)
            Text(verbatim: Copywriter.todoGateTitle)
                .font(Typography.cardTitle)
                .foregroundStyle(Night.text)
            Text(verbatim: engine.todoAccess == .denied ? Copywriter.todoGateDenied : Copywriter.todoGateNotAsked)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .multilineTextAlignment(.center)
            if engine.todoAccess == .denied {
                Button { engine.openTodoSettings() } label: { Text(verbatim: Copywriter.todoOpenSettings) }
                    .buttonStyle(GhostButton(accent: Night.todo))
                    .accessibilityIdentifier("todos.access.open")
            } else {
                Button { Task { await engine.requestTodoAccess() } } label: { Text(verbatim: Copywriter.todoAllowAccess) }
                    .buttonStyle(GhostButton(accent: Night.todo))
                    .accessibilityIdentifier("todos.access.allow")
            }
        }
        .padding(UIMetrics.todoFormPadding)
        .frame(width: UIMetrics.todoGateWidth)
    }
}
