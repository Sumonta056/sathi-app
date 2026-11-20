import Foundation

enum TodoFinishPhase {
    case checked
    case leaving
}

@MainActor
final class TodoFinishing: ObservableObject {
    @Published private(set) var phases: [String: TodoFinishPhase] = [:]
    private var tasks: [String: Task<Void, Never>] = [:]
    private let wait: (TimeInterval) async -> Void
    private var write: (String) -> Void

    init(
        wait: @escaping (TimeInterval) async -> Void = TodoFinishing.sleep,
        write: @escaping (String) -> Void
    ) {
        self.wait = wait
        self.write = write
    }

    nonisolated static func sleep(_ delay: TimeInterval) async {
        try? await Task.sleep(for: .seconds(delay))
    }

    func bind(_ write: @escaping (String) -> Void) {
        self.write = write
    }

    func phase(_ id: String) -> TodoFinishPhase? {
        phases[id]
    }

    func tick(_ id: String) {
        switch phases[id] {
        case .checked:
            tasks[id]?.cancel()
            tasks[id] = nil
            phases[id] = nil
        case .leaving:
            return
        case nil:
            phases[id] = .checked
            tasks[id] = Task { [weak self, wait] in
                await wait(UIMetrics.todoHoldSeconds)
                guard !Task.isCancelled, let self else { return }
                phases[id] = .leaving
                await wait(UIMetrics.todoFoldSeconds)
                guard !Task.isCancelled else { return }
                commit(id)
            }
        }
    }

    func flush() {
        for id in Array(phases.keys) {
            commit(id)
        }
    }

    func flush(_ id: String) {
        guard phases[id] != nil else { return }
        commit(id)
    }

    private func commit(_ id: String) {
        tasks[id]?.cancel()
        tasks[id] = nil
        write(id)
        phases[id] = nil
    }
}
