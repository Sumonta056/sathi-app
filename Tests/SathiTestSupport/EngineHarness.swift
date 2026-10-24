import Foundation
import SathiCore

package func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

@MainActor
package struct EngineHarness {
    package let engine: Engine
    package let clock: FakeClock
    package let store: InMemoryStateStore
    package let sound: SpySoundPlayer
    package let presenter: SpyPresenter

    package init(at start: Date = day(2026, 3, 4, 10), configure: (inout Persisted) -> Void = { _ in }) {
        var state = Persisted()
        configure(&state)
        clock = FakeClock(start)
        store = InMemoryStateStore(state)
        sound = SpySoundPlayer()
        presenter = SpyPresenter()
        engine = Engine(store: store, clock: clock, sound: sound, presenter: presenter)
        engine.tick()
    }

    package func advance(minutes: Double) {
        clock.advance(minutes: minutes)
        engine.tick()
    }

    package func showReminder(_ id: HabitID) {
        engine.trigger(id)
    }
}
