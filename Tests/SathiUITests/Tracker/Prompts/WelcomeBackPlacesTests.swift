import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Welcome back places")
struct WelcomeBackPlacesTests {
    private func state(
        _ calls: PromptCalls = PromptCalls(), place: AwayPlace? = nil, name: String? = nil, places: [String] = []
    ) -> TrackerPromptState {
        Prompt.state(.welcomeBack, calls: calls) {
            $0.lastActivity = ActivityDraft(text: "Coding")
            $0.away = AwaySpan(start: Prompt.now.addingTimeInterval(-2700), end: Prompt.now, cause: .locked, place: place, placeName: name)
            $0.places = places
        }
    }

    private func view(_ s: TrackerPromptState, _ form: WelcomeForm? = nil) throws -> InspectableView<ViewType.ClassifiedView> {
        try AnyView(WelcomeBackView(state: s, form: form)).inspect()
    }

    @Test func theFormStartsFromTheState() {
        let form = WelcomeForm(state(place: .other, name: "Doctor", places: ["Doctor", "Gym"]))
        #expect(form.place == .other)
        #expect(form.placeName == "Doctor")
        #expect(form.places == ["Doctor", "Gym"])
        #expect(!form.adding)
        #expect(form.newName == "")
    }

    @Test func aTapOnAPlaceChipSelectsItInAViewBuiltAgainWithTheSameForm() throws {
        let calls = PromptCalls()
        let s = state(calls)
        let form = WelcomeForm(s)
        #expect(try !Prompt.chipIsOn(view(s, form), "tracker.place.lunch"))
        try Prompt.tap(view(s, form), "tracker.place.lunch")
        #expect(try Prompt.chipIsOn(view(s, form), "tracker.place.lunch"))
        #expect(try !Prompt.chipIsOn(view(s, form), "tracker.place.walk"))
        #expect(calls.places == [.lunch])
        #expect(form.place == .lunch)
        #expect(form.placeName == nil)
    }

    @Test(arguments: AwayPlace.choices)
    func everyBuiltInChipPicksItsPlace(_ place: AwayPlace) throws {
        let calls = PromptCalls()
        let s = state(calls)
        let form = WelcomeForm(s)
        try Prompt.tap(view(s, form), "tracker.place." + place.rawValue)
        #expect(calls.places == [place])
        #expect(calls.placeNames.isEmpty)
        let on = try AwayPlace.choices.filter { try Prompt.chipIsOn(view(s, form), "tracker.place." + $0.rawValue) }
        #expect(on == [place])
    }

    @Test func withoutAFormTheChipOfTheStatePlaceIsSelected() throws {
        let sut = try view(state(place: .walk))
        #expect(try Prompt.chipIsOn(sut, "tracker.place.walk"))
        #expect(try !Prompt.chipIsOn(sut, "tracker.place.lunch"))
    }

    @Test func eachSavedPlaceHasAChipAfterTheBuiltInChips() throws {
        let sut = try view(state(places: ["Doctor", "School run"]))
        let ids = Prompt.ids(sut, prefix: "tracker.place.")
        #expect(ids == [
            "tracker.place.lunch", "tracker.place.meeting", "tracker.place.walk", "tracker.place.commute", "tracker.place.other",
            "tracker.place.custom.Doctor", "tracker.place.custom.School run", "tracker.place.add"
        ])
        let labels = sut.findAll(TrackerChip.self).compactMap { try? $0.actualView() }
            .filter { $0.id.hasPrefix("tracker.place.custom.") }.map(\.label)
        #expect(labels == ["Doctor", "School run"])
    }

    @Test func aTapOnACustomChipPicksOtherWithTheName() throws {
        let calls = PromptCalls()
        let s = state(calls, places: ["Doctor", "Gym"])
        let form = WelcomeForm(s)
        try Prompt.tap(view(s, form), "tracker.place.custom.Doctor")
        #expect(form.place == .other)
        #expect(form.placeName == "Doctor")
        #expect(calls.placeNames == ["Doctor"])
        #expect(calls.places.isEmpty)
        #expect(try Prompt.chipIsOn(view(s, form), "tracker.place.custom.Doctor"))
        #expect(try !Prompt.chipIsOn(view(s, form), "tracker.place.custom.Gym"))
        #expect(try !Prompt.chipIsOn(view(s, form), "tracker.place.other"))
    }

    @Test func aBuiltInTapAfterACustomPickClearsTheName() throws {
        let calls = PromptCalls()
        let s = state(calls, place: .other, name: "Doctor", places: ["Doctor"])
        let form = WelcomeForm(s)
        #expect(try Prompt.chipIsOn(view(s, form), "tracker.place.custom.Doctor"))
        try Prompt.tap(view(s, form), "tracker.place.other")
        #expect(form.place == .other)
        #expect(form.placeName == nil)
        #expect(calls.places == [.other])
        #expect(try Prompt.chipIsOn(view(s, form), "tracker.place.other"))
        #expect(try !Prompt.chipIsOn(view(s, form), "tracker.place.custom.Doctor"))
    }

    @Test func theAddChipOpensTheAddRow() throws {
        let s = state()
        let form = WelcomeForm(s)
        let closed = try view(s, form)
        #expect(Prompt.has(closed, "tracker.place.add"))
        #expect(!Prompt.has(closed, "tracker.place.save"))
        #expect(!Prompt.hasText(closed, Copywriter.trackerPlaceKept))
        #expect(closed.findAll(LazyTextField.self).isEmpty)
        try Prompt.tap(closed, "tracker.place.add")
        #expect(form.adding)
        let open = try view(s, form)
        #expect(!Prompt.has(open, "tracker.place.add"))
        #expect(try Prompt.buttonText(open, "tracker.place.save") == ["Add"])
        #expect(Prompt.hasText(open, "Sathi keeps this place as a chip. Remove it in Settings → Activity tracker."))
        #expect(try open.find(LazyTextField.self).actualView().placeholder == "New place")
    }

    @Test(arguments: [7, 8])
    func theAddChipHidesAtEightPlaces(_ count: Int) throws {
        let sut = try view(state(places: (1 ... count).map { "P\($0)" }))
        #expect(Prompt.has(sut, "tracker.place.add") == (count < 8))
        #expect(Prompt.ids(sut, prefix: "tracker.place.custom.").count == count)
    }
}
