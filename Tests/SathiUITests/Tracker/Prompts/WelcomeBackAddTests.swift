import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Welcome back add place")
struct WelcomeBackAddTests {
    private let eight = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]

    private func state(_ calls: PromptCalls, places: [String] = []) -> TrackerPromptState {
        Prompt.state(.welcomeBack, calls: calls) {
            $0.lastActivity = ActivityDraft(text: "Coding")
            $0.away = AwaySpan(start: Prompt.now.addingTimeInterval(-2700), end: Prompt.now, cause: .locked)
            $0.places = places
        }
    }

    private func adding(_ s: TrackerPromptState, _ name: String) -> WelcomeForm {
        let form = WelcomeForm(s)
        form.adding = true
        form.newName = name
        return form
    }

    private func view(_ s: TrackerPromptState, _ form: WelcomeForm) throws -> InspectableView<ViewType.ClassifiedView> {
        try AnyView(WelcomeBackView(state: s, form: form)).inspect()
    }

    @Test func saveAddsTheCleanNameSelectsItAndClosesTheRow() throws {
        let calls = PromptCalls()
        let s = state(calls, places: ["Gym"])
        let form = adding(s, "  Doctor ")
        try Prompt.tap(view(s, form), "tracker.place.save")
        #expect(form.places == ["Gym", "Doctor"])
        #expect(form.place == .other)
        #expect(form.placeName == "Doctor")
        #expect(calls.addedPlaces == ["Doctor"])
        #expect(!form.adding)
        #expect(form.newName == "")
        let sut = try view(s, form)
        #expect(try Prompt.chipIsOn(sut, "tracker.place.custom.Doctor"))
        #expect(try !Prompt.chipIsOn(sut, "tracker.place.custom.Gym"))
        #expect(try !Prompt.chipIsOn(sut, "tracker.place.other"))
        #expect(Prompt.has(sut, "tracker.place.add"))
        #expect(!Prompt.has(sut, "tracker.place.save"))
    }

    @Test func enterInTheFieldSavesToo() throws {
        let calls = PromptCalls()
        let s = state(calls)
        let form = adding(s, "Doctor")
        try view(s, form).find(LazyTextField.self).actualView().onSubmit()
        #expect(form.places == ["Doctor"])
        #expect(form.placeName == "Doctor")
        #expect(calls.addedPlaces == ["Doctor"])
        #expect(!form.adding)
        #expect(form.newName == "")
    }

    @Test func aLongNameIsCutToTwentyFourCharacters() throws {
        let calls = PromptCalls()
        let s = state(calls)
        let form = adding(s, String(repeating: "a", count: 40))
        try Prompt.tap(view(s, form), "tracker.place.save")
        let cut = String(repeating: "a", count: 24)
        #expect(form.places == [cut])
        #expect(form.placeName == cut)
        #expect(calls.addedPlaces == [cut])
    }

    @Test func theEighthPlaceIsSavedAndThenTheAddChipHides() throws {
        let calls = PromptCalls()
        let s = state(calls, places: Array(eight.dropLast()))
        let form = adding(s, "P8")
        try Prompt.tap(view(s, form), "tracker.place.save")
        #expect(form.places == eight)
        #expect(calls.addedPlaces == ["P8"])
        #expect(try !Prompt.has(view(s, form), "tracker.place.add"))
    }

    @Test(arguments: ["", "   ", "Lunch", "meeting", "OTHER", "break", "Gym", " gym "])
    func aRefusedNameChangesNothing(_ name: String) throws {
        let calls = PromptCalls()
        let s = state(calls, places: ["Gym"])
        let form = adding(s, name)
        form.place = .walk
        try Prompt.tap(view(s, form), "tracker.place.save")
        try view(s, form).find(LazyTextField.self).actualView().onSubmit()
        #expect(form.places == ["Gym"])
        #expect(form.place == .walk)
        #expect(form.placeName == nil)
        #expect(form.adding)
        #expect(form.newName == name)
        #expect(calls.addedPlaces.isEmpty)
        #expect(calls.placeNames.isEmpty)
    }

    @Test func aNinthNameChangesNothing() throws {
        let calls = PromptCalls()
        let s = state(calls, places: eight)
        let form = adding(s, "P9")
        try Prompt.tap(view(s, form), "tracker.place.save")
        #expect(form.places == eight)
        #expect(form.placeName == nil)
        #expect(form.adding)
        #expect(calls.addedPlaces.isEmpty)
    }

    @Test func theSavedLineNamesTheNewPlaceAfterTheAdd() throws {
        let calls = PromptCalls()
        let s = state(calls)
        let form = adding(s, "Doctor")
        try Prompt.tap(view(s, form), "tracker.place.save")
        let span = Copywriter.trackerSpan(Prompt.now.addingTimeInterval(-2700), Prompt.now, calendar: Prompt.calendar)
        #expect(try Prompt.hasText(view(s, form), "Sathi saves " + span + " as Away · Doctor"))
    }
}
