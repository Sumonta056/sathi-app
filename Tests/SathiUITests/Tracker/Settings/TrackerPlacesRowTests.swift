import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker places row")
struct TrackerPlacesRowTests {
    private let prefix = "settings.tracker.place.remove."

    private func harness(_ places: [String]) -> EngineHarness {
        EngineHarness { $0.prefs.tracker.isOn = true; $0.prefs.tracker.awayPlaces = places }
    }

    private func row(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TrackerPlacesRow(), h).inspect()
    }

    private func tap(_ sut: InspectableView<some BaseViewType>, _ id: String) throws {
        let view = try sut.find(viewWithAccessibilityIdentifier: id)
        if let b = try? view.button() { try b.tap() } else { try view.find(ViewType.Button.self, relation: .parent).tap() }
    }

    private func ids(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(where: { (try? $0.accessibilityIdentifier())?.hasPrefix(prefix) == true })
            .compactMap { try? $0.accessibilityIdentifier() }
    }

    @Test func theRowHasItsLabel() throws {
        _ = try row(harness(["Doctor"])).find(text: "Away places")
    }

    @Test func eachPlaceHasARemoveButtonInOrder() throws {
        let sut = try row(harness(["Doctor", "School run", "Gym"]))
        #expect(ids(sut) == [prefix + "Doctor", prefix + "School run", prefix + "Gym"])
        #expect(Find.lacks(sut, text: "Add a place in the Welcome back popup."))
    }

    @Test func aTapRemovesThatPlaceFromPrefs() throws {
        let h = harness(["Doctor", "School run", "Gym"])
        try tap(row(h), prefix + "School run")
        #expect(h.store.prefs.tracker.awayPlaces == ["Doctor", "Gym"])
        #expect(h.engine.awayPlaces == ["Doctor", "Gym"])
        #expect(try ids(row(h)) == [prefix + "Doctor", prefix + "Gym"])
    }

    @Test func removingTheLastPlaceShowsTheEmptyText() throws {
        let h = harness(["Doctor"])
        try tap(row(h), prefix + "Doctor")
        #expect(h.store.prefs.tracker.awayPlaces == [])
        let sut = try row(h)
        #expect(ids(sut).isEmpty)
        _ = try sut.find(text: "Add a place in the Welcome back popup.")
    }

    @Test func anEmptyListShowsTheEmptyTextAndNoButton() throws {
        let sut = try row(harness([]))
        _ = try sut.find(text: "Add a place in the Welcome back popup.")
        _ = try sut.find(text: "Away places")
        #expect(ids(sut).isEmpty)
    }

    @Test func theRowSitsInTheMoreCard() throws {
        let sut = try hosted(TrackerMoreCard(), harness(["Doctor"])).inspect()
        #expect(throws: Never.self) { try sut.find(TrackerPlacesRow.self) }
        _ = try sut.find(text: "Away places")
        #expect(ids(sut) == [prefix + "Doctor"])
        _ = try sut.find(text: Copywriter.trackerEndOfDayLabel)
        _ = try sut.find(text: Copywriter.trackerSoundLabel)
    }

    @Test func theSettingsPageShowsTheRow() throws {
        let sut = try hosted(TrackerSettingsPage(), harness(["Doctor"])).inspect()
        _ = try sut.find(text: "Away places")
        #expect(ids(sut) == [prefix + "Doctor"])
    }
}
