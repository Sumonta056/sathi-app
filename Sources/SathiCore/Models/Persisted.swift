import Foundation

package struct Persisted: Equatable, Sendable {
    package var prefs = Prefs()
    package var live = LiveState()
    package var events: [HistoryEvent] = []

    package init() {}

    package func lastDone(_ id: HabitID) -> Date? {
        switch id {
        case .water: return live.lastWaterDone
        case .reading: return nil
        }
    }
}
