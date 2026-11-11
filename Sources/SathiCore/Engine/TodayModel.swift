import Combine
import Foundation

@MainActor
package final class TodayModel: ObservableObject {
    @Published package private(set) var screen: TodayScreen?
    private var subscription: AnyCancellable?
    private var pending = false

    package init() {}

    package func attach(_ engine: Engine) {
        refresh(engine)
        subscription = engine.objectWillChange
            .sink { [weak self, weak engine] _ in
                guard let self, !pending else { return }
                pending = true
                DispatchQueue.main.async { [weak self, weak engine] in
                    guard let self else { return }
                    pending = false
                    if let engine, subscription != nil { refresh(engine) }
                }
            }
    }

    package func detach() {
        subscription = nil
    }

    private func refresh(_ engine: Engine) {
        let built = engine.todayScreen
        if screen != built { screen = built }
    }
}
