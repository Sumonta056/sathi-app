import SathiCore
import SwiftUI

struct TodoAccessGate: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let denied = engine.todoAccess == .denied
        AccessGateCard(
            icon: "checkmark.circle",
            accent: Night.todo,
            title: Copywriter.todoGateTitle,
            message: denied ? Copywriter.todoGateDenied : Copywriter.todoGateNotAsked,
            button: denied ? Copywriter.todoOpenSettings : Copywriter.todoAllowAccess,
            buttonID: denied ? "todos.access.open" : "todos.access.allow"
        ) {
            if denied { engine.openTodoSettings() } else { Task { await engine.requestTodoAccess() } }
        }
    }
}
