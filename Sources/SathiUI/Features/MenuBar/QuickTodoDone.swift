import SathiCore

enum QuickTodoDone {
    @MainActor
    static func write(_ engine: Engine, _ finishing: TodoFinishing) -> (String) -> Void {
        { id in
            Task {
                let saved = await engine.doneTodoNow(id)
                finishing.resolve(id, failed: !saved, open: Set(engine.todoSnapshot.open.map(\.id)))
            }
        }
    }
}
