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

    static func toolTexts(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(ToolRow.self).flatMap { MenuFind.texts($0) }
    }

    static func toolButtons(_ sut: InspectableView<some BaseViewType>) -> Int {
        sut.findAll(ToolRow.self).map { $0.findAll(ViewType.Button.self).count }.reduce(0, +)
    }

    static func fixedWidth(_ button: InspectableView<ViewType.Button>) -> CGFloat? {
        if let w = try? button.fixedWidth() { return w }
        return button.findAll(where: { (try? $0.fixedWidth()) != nil }).compactMap { try? $0.fixedWidth() }.first
    }
}
