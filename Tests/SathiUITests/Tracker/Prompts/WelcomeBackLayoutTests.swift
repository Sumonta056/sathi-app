import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Welcome back layout")
struct WelcomeBackLayoutTests {
    private let start = Prompt.now.addingTimeInterval(-45 * 60)

    private var span: String { Copywriter.trackerSpan(start, Prompt.now, calendar: Prompt.calendar) }

    private func state(
        cause: AwayCause = .locked, place: AwayPlace? = nil, name: String? = nil, last: String? = "Coding"
    ) -> TrackerPromptState {
        Prompt.state(.welcomeBack) {
            $0.lastActivity = last.map { ActivityDraft(text: $0) }
            $0.away = AwaySpan(start: start, end: Prompt.now, cause: cause, place: place, placeName: name)
            $0.places = ["Doctor"]
        }
    }

    private func view(_ s: TrackerPromptState, _ form: WelcomeForm? = nil) throws -> InspectableView<ViewType.ClassifiedView> {
        try AnyView(WelcomeBackView(state: s, form: form)).inspect()
    }

    @Test func theHeaderHasTheAwayEyebrowAndTheNewTitle() throws {
        let header = try view(state()).find(TrackerHeader.self).actualView()
        #expect(header.eyebrow == "AWAY " + span + " · 45 MIN")
        #expect(header.title == "Welcome back. Where were you?")
    }

    @Test func theTwoStepsAreNumberedAndNamed() throws {
        let texts = try Prompt.texts(view(state()))
        let wanted = ["1", "Where were you?", "2", "What now?"]
        #expect(texts.filter(wanted.contains) == wanted)
    }

    @Test func thePlacesComeBeforeTheWhatNowButtons() throws {
        let ids = try Prompt.ids(view(state(cause: .idle)), prefix: "tracker.")
        let wanted = ["tracker.place.lunch", "tracker.place.custom.Doctor", "tracker.place.add", "tracker.back", "tracker.new", "tracker.here"]
        #expect(ids.filter(wanted.contains) == wanted)
    }

    @Test func theMainButtonSaysContinueWithTheLastActivity() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.welcomeBack, calls: calls) {
            $0.lastActivity = ActivityDraft(text: "Nuxt version work")
            $0.away = AwaySpan(start: start, end: Prompt.now, cause: .locked)
        }
        let sut = try view(s)
        #expect(try Prompt.buttonText(sut, "tracker.back") == ["Continue Nuxt version work", "↵"])
        #expect(!Prompt.texts(sut).contains { $0.hasPrefix("Back to") })
        try Prompt.tap(sut, "tracker.back")
        #expect(calls.calls == ["back"])
    }

    @Test func thereIsNoContinueButtonWithoutALastActivity() throws {
        let sut = try view(state(last: nil))
        #expect(!Prompt.has(sut, "tracker.back"))
        #expect(Prompt.has(sut, "tracker.new"))
        #expect(Prompt.hasText(sut, "What now?"))
    }

    @Test func startSomethingNewIsAButtonAndTheFieldIsNotShownYet() throws {
        let sut = try view(state())
        #expect(try Prompt.buttonText(sut, "tracker.new") == ["Start something new"])
        #expect(!Prompt.hasText(sut, "Something new"))
        #expect(sut.findAll(LazyTextField.self).isEmpty)
    }

    @Test func startSomethingNewAndIWasHereShareOneRow() throws {
        let sut = try view(state(cause: .idle))
        let rows = sut.findAll(ViewType.HStack.self).filter {
            Prompt.has($0, "tracker.new") && Prompt.has($0, "tracker.here") && !Prompt.has($0, "tracker.back")
                && !Prompt.has($0, "tracker.place.lunch")
        }
        #expect(!rows.isEmpty)
        #expect(try Prompt.buttonText(sut, "tracker.here") == ["I was here"])
    }

    @Test func iWasHereShowsOnlyAfterIdle() throws {
        #expect(try !Prompt.has(view(state()), "tracker.here"))
        #expect(try Prompt.has(view(state(cause: .idle)), "tracker.here"))
    }

    @Test func theKeyHintNamesContinueAndEsc() throws {
        let sut = try view(state())
        #expect(Prompt.hasText(sut, "↵ continue · esc keep as Away"))
        #expect(!Prompt.texts(sut).contains { $0.contains("back to it") })
    }

    @Test func theSavedLineWithoutAPlace() throws {
        #expect(try Prompt.hasText(view(state()), "Sathi saves " + span + " as Away"))
    }

    @Test(arguments: [(AwayPlace.lunch, "Lunch"), (.meeting, "Meeting"), (.walk, "Walk"), (.commute, "Commute"), (.other, "Other")])
    func theSavedLineNamesTheSelectedPlace(_ place: AwayPlace, _ label: String) throws {
        #expect(try Prompt.hasText(view(state(place: place)), "Sathi saves " + span + " as Away · " + label))
    }

    @Test func theSavedLineNamesTheCustomPlace() throws {
        #expect(try Prompt.hasText(view(state(place: .other, name: "Doctor")), "Sathi saves " + span + " as Away · Doctor"))
    }

    @Test func theSavedLineFollowsATapOnAChip() throws {
        let s = state()
        let form = WelcomeForm(s)
        try Prompt.tap(view(s, form), "tracker.place.commute")
        #expect(try Prompt.hasText(view(s, form), "Sathi saves " + span + " as Away · Commute"))
        try Prompt.tap(view(s, form), "tracker.place.custom.Doctor")
        #expect(try Prompt.hasText(view(s, form), "Sathi saves " + span + " as Away · Doctor"))
        #expect(try Prompt.texts(view(s, form)).filter { $0.hasPrefix("Sathi saves") }.count == 1)
    }

    @Test func thereIsNoSavedLineWithoutAnAway() throws {
        let s = Prompt.state(.welcomeBack) { $0.lastActivity = ActivityDraft(text: "Coding") }
        let sut = try view(s)
        #expect(!Prompt.texts(sut).contains { $0.hasPrefix("Sathi saves") })
        #expect(Prompt.has(sut, "tracker.place.lunch"))
    }
}
