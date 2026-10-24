import SathiCore
import SwiftUI

extension Engine {
    func enabledBinding(_ id: HabitID) -> Binding<Bool> {
        Binding(get: { self.data.prefs.isEnabled(id) }, set: { self.setEnabled(id, $0) })
    }

    private func setEnabled(_ id: HabitID, _ on: Bool) {
        switch id {
        case .water: data.prefs.water.enabled = on
        case .reading: data.prefs.reading.enabled = on
        case .meditation: data.prefs.meditation.enabled = on
        }
    }
}
