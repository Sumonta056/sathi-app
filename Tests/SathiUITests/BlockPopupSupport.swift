import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

@MainActor
extension Block {
    static func finished() -> EngineHarness {
        let h = running(.minutes(30))
        h.advance(minutes: 30)
        return h
    }

    static func checkIn() -> EngineHarness {
        let h = running(.open)
        h.advance(minutes: 120)
        return h
    }

    static func goneHarness() -> EngineHarness {
        let h = running(.minutes(30), after: 5)
        h.calendarWriter.nextSaveResult = .calendarMissing
        h.calendarWriter.choices.removeAll { $0.id == "work" }
        h.engine.refreshCalendarAccess()
        h.engine.endBlock()
        return h
    }

    static func view(_ view: some View, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(view, h).inspect()
    }

    static func tap(_ sut: InspectableView<some BaseViewType>, id: String) throws {
        try sut.find(viewWithAccessibilityIdentifier: id).find(ViewType.Button.self, relation: .parent).tap()
    }
}
