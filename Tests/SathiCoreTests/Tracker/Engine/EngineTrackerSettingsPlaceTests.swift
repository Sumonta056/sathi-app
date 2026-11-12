import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker settings place")
struct EngineTrackerSettingsPlaceTests {
    private func welcomeBack() -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.awayPlaces = ["Doctor"] }
        h.start("Write spec", minutes: 30)
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 0.5)
        h.engine.presenceChanged(.unlocked)
        return h
    }

    @Test func addingFromSettingsDuringWelcomeBackKeepsTheAwayUntagged() {
        let h = welcomeBack()
        #expect(h.promptKind == .welcomeBack)
        #expect(h.engine.addAwayPlace("Cafe", tagsLastAway: false))
        #expect(h.engine.awayPlaces == ["Doctor", "Cafe"])
        #expect(h.engine.trackerPromptState(.welcomeBack)?.away?.place == nil)
        #expect(h.engine.trackerPromptState(.welcomeBack)?.away?.placeName == nil)
        #expect(h.saved.filter { $0.kind == .away }.allSatisfy { $0.awayPlace == nil })
    }

    @Test func addingFromThePromptStillTagsTheAway() {
        let h = welcomeBack()
        #expect(h.engine.addAwayPlace("Cafe"))
        #expect(h.engine.trackerPromptState(.welcomeBack)?.away?.placeName == "Cafe")
    }

    @Test func settingsRefusesDuplicatesAndBuiltInNames() {
        let h = welcomeBack()
        #expect(!h.engine.addAwayPlace("doctor", tagsLastAway: false))
        #expect(!h.engine.addAwayPlace("Lunch", tagsLastAway: false))
        #expect(h.engine.awayPlaces == ["Doctor"])
    }
}
