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
        _ = try row(harness(["Doctor"])).find(text: Copywriter.trackerPlacesHint)
    }

    @Test func theHintNamesWhereThePlacesShow() {
        #expect(Copywriter.trackerPlacesHint == "They show in the Away row of every popup and in Welcome back.")
    }

    @Test func builtInPlacesShowReadOnlyWithNoRemoveButton() throws {
        let sut = try row(harness([]))
        _ = try sut.find(text: "Built in")
        for place in AwayPlace.choices {
            _ = try sut.find(text: Copywriter.trackerAwayPlace(place))
        }
        #expect(ids(sut).isEmpty)
        #expect(sut.findAll(ViewType.Button.self).filter { (try? $0.labelView().find(text: "Lunch")) != nil }.isEmpty)
    }

    @Test func yoursShowsOnlyWhenThereIsAUserPlace() throws {
        #expect(try Find.lacks(row(harness([])), text: "Yours"))
        _ = try row(harness(["Doctor"])).find(text: "Yours")
    }

    @Test func eachPlaceHasARemoveButtonInOrder() throws {
        let sut = try row(harness(["Doctor", "School run", "Gym"]))
        #expect(ids(sut) == [prefix + "Doctor", prefix + "School run", prefix + "Gym"])
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
        #expect(Find.lacks(sut, text: "Yours"))
    }

    @Test func anEmptyListShowsNoRemoveButton() throws {
        let sut = try row(harness([]))
        _ = try sut.find(text: "Away places")
        #expect(ids(sut).isEmpty)
    }

    @Test func theNewPlaceFieldAndAddButtonShow() throws {
        let sut = try row(harness(["Doctor"]))
        #expect(throws: Never.self) { try lazyField(sut, "New place") }
        #expect(throws: Never.self) { try sut.find(button: "+ Add place") }
    }

    @Test func theFieldAndButtonHideAtTheMax() throws {
        let names = (1 ... Limits.awayPlaceMax).map { "P\($0)" }
        let sut = try row(harness(names))
        #expect(sut.findAll(LazyTextField.self).isEmpty)
        #expect(Find.lacks(sut, text: "+ Add place"))
    }

    @Test func theFieldComesBackWhenOnePlaceIsRemoved() throws {
        let names = (1 ... Limits.awayPlaceMax).map { "P\($0)" }
        let h = harness(names)
        try tap(row(h), prefix + "P1")
        #expect(throws: Never.self) { try lazyField(row(h), "New place") }
    }

    private func addRow(_ h: EngineHarness, _ state: PlaceNameState) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(state.row(), h).inspect()
    }

    @Test func addButtonSavesThePlaceAndClearsTheField() throws {
        let h = harness(["Doctor"])
        let state = PlaceNameState("  Cafe ")
        try addRow(h, state).find(button: "+ Add place").tap()
        #expect(h.store.prefs.tracker.awayPlaces == ["Doctor", "Cafe"])
        #expect(state.value.isEmpty)
    }

    @Test func returnInTheFieldAdds() throws {
        let h = harness([])
        let state = PlaceNameState("Cafe")
        try lazyField(addRow(h, state), "New place").onSubmit()
        #expect(h.engine.awayPlaces == ["Cafe"])
        #expect(state.value.isEmpty)
    }

    @Test(arguments: ["doctor", " DOCTOR ", "Lunch", "lunch", "Other", "", "   "])
    func aRefusedNameChangesNothingAndKeepsTheText(_ text: String) throws {
        let h = harness(["Doctor"])
        let state = PlaceNameState(text)
        try addRow(h, state).find(button: "+ Add place").tap()
        #expect(h.engine.awayPlaces == ["Doctor"])
        #expect(state.value == text)
    }

    @Test func theNewPlaceShowsAsAChipAfterAdding() throws {
        let h = harness([])
        let state = PlaceNameState("Cafe")
        try addRow(h, state).find(button: "+ Add place").tap()
        #expect(try ids(row(h)) == [prefix + "Cafe"])
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

@MainActor
final class PlaceNameState {
    var value: String

    init(_ value: String = "") {
        self.value = value
    }

    func row() -> TrackerPlaceAddRow {
        TrackerPlaceAddRow(text: Binding(get: { self.value }, set: { self.value = $0 }))
    }
}
