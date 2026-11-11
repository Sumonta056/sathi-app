import Combine
import Foundation

@MainActor
package final class TodayModel: ObservableObject {
    @Published package private(set) var screen: TodayScreen?
    private var subscription: AnyCancellable?

    package init() {}

    package func attach(_ engine: Engine) {
        refresh(engine)
        subscription = engine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak engine] _ in
                guard let self, let engine else { return }
                refresh(engine)
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
