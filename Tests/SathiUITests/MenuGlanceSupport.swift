import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

@MainActor
enum Glance {
    static func harness(reminders: Int = 0, block: TimeBlockLength? = nil, denied: Bool = false) -> EngineHarness {
        let h = EngineHarness(at: Quick.now) {
            $0.prefs.water.enabled = true
            $0.prefs.reading.enabled = true
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
            $0.live.quickReminders = Quick.many(reminders)
        }
        if let block { h.startBlock("Plan", block) }
        if denied {
            h.calendarWriter.access = .denied
            h.engine.refreshCalendarAccess()
        }
        return h
    }

    static func panel(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(MenuPanel(), h).inspect()
    }
}
