import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import ViewInspector

@MainActor
enum BlockSettings {
    static func page(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TimeBlockSettingsPage(), h).inspect()
    }

    static func harness(access: CalendarAccess = .allowed, _ configure: (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        let h = Block.harness(configure)
        h.calendarWriter.access = access
        h.engine.refreshCalendarAccess()
        return h
    }

    static func control(_ sut: InspectableView<some BaseViewType>, _ id: String) throws -> InspectableView<ViewType.Button> {
        let view = try sut.find(viewWithAccessibilityIdentifier: id)
        if let b = try? view.button() { return b }
        return try view.find(ViewType.Button.self, relation: .parent)
    }

    static func has(_ sut: InspectableView<some BaseViewType>, _ id: String) -> Bool {
        (try? sut.find(viewWithAccessibilityIdentifier: id)) != nil
    }

    static func tap(_ sut: InspectableView<some BaseViewType>, _ id: String) throws {
        try control(sut, id).tap()
    }

    static func texts(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }
}
