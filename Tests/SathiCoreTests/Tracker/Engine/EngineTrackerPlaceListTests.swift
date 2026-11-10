import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker place list")
struct EngineTrackerPlaceListTests {
    private let eight = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8"]

    private func harness(_ places: [String] = []) -> EngineHarness {
        EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.awayPlaces = places }
    }

    private func away(_ h: EngineHarness) {
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 30)
        h.engine.presenceChanged(.unlocked)
    }

    private func awayItems(_ h: EngineHarness) -> [Activity] { h.saved.filter { $0.kind == .away } }

    private func state(_ h: EngineHarness) -> TrackerPromptState? { h.engine.trackerPromptState(.welcomeBack) }

    @Test func addSavesThePlaceInPrefs() {
        let h = harness(["Gym"])
        #expect(h.engine.addAwayPlace("Doctor"))
        #expect(h.engine.awayPlaces == ["Gym", "Doctor"])
        #expect(h.store.prefs.tracker.awayPlaces == ["Gym", "Doctor"])
    }

    @Test func addSavesTheCleanName() {
        let h = harness()
        #expect(h.engine.addAwayPlace("  Doctor \n"))
        #expect(h.store.prefs.tracker.awayPlaces == ["Doctor"])
        let long = String(repeating: "a", count: 40)
        #expect(h.engine.addAwayPlace(long))
        #expect(h.store.prefs.tracker.awayPlaces == ["Doctor", String(repeating: "a", count: 24)])
    }

    @Test func addPicksThePlaceWhenWelcomeBackShows() {
        let h = harness()
        away(h)
        #expect(h.engine.addAwayPlace(" Doctor "))
        #expect(state(h)?.away?.place == .other)
        #expect(state(h)?.away?.placeName == "Doctor")
        #expect(state(h)?.places == ["Doctor"])
        #expect(awayItems(h).map(\.awayPlace) == [.other])
        #expect(awayItems(h).map(\.awayPlaceName) == ["Doctor"])
        #expect(awayItems(h).map(\.text) == ["Away · Doctor"])
    }

    @Test func addWithNoPromptChangesNoActivity() {
        let h = harness()
        away(h)
        h.engine.closeTrackerPrompt()
        let before = h.saved
        #expect(h.engine.addAwayPlace("Doctor"))
        #expect(h.saved == before)
        #expect(h.store.prefs.tracker.awayPlaces == ["Doctor"])
    }

    @Test(arguments: ["", "   ", "Lunch", "meeting", "OTHER", "Break", "Gym", "gym", " GYM "])
    func aRefusedAddReturnsFalseAndChangesNothing(_ name: String) {
        let h = harness(["Gym"])
        away(h)
        h.engine.setAwayPlace(.walk)
        let before = h.saved
        #expect(!h.engine.addAwayPlace(name))
        #expect(h.engine.awayPlaces == ["Gym"])
        #expect(h.store.prefs.tracker.awayPlaces == ["Gym"])
        #expect(h.saved == before)
        #expect(state(h)?.away?.place == .walk)
        #expect(state(h)?.away?.placeName == nil)
    }

    @Test func aNinthPlaceIsRefused() {
        let h = harness(eight)
        away(h)
        #expect(!h.engine.addAwayPlace("P9"))
        #expect(h.store.prefs.tracker.awayPlaces == eight)
        #expect(state(h)?.away?.place == nil)
        #expect(awayItems(h).map(\.text) == ["Away"])
    }

    @Test func theEighthPlaceIsAccepted() {
        let h = harness(Array(eight.dropLast()))
        #expect(h.engine.addAwayPlace("P8"))
        #expect(h.store.prefs.tracker.awayPlaces == eight)
    }

    @Test func removeTakesThePlaceOutOfPrefs() {
        let h = harness(["Doctor", "Gym", "School run"])
        h.engine.removeAwayPlace("Gym")
        #expect(h.engine.awayPlaces == ["Doctor", "School run"])
        #expect(h.store.prefs.tracker.awayPlaces == ["Doctor", "School run"])
    }

    @Test func removeOfAnUnknownNameChangesNothing() {
        let h = harness(["Doctor"])
        h.engine.removeAwayPlace("Dentist")
        #expect(h.store.prefs.tracker.awayPlaces == ["Doctor"])
    }

    @Test func aRemovedPlaceCanBeAddedAgain() {
        let h = harness(["Doctor"])
        h.engine.removeAwayPlace("Doctor")
        #expect(h.engine.addAwayPlace("Doctor"))
        #expect(h.store.prefs.tracker.awayPlaces == ["Doctor"])
    }

    @Test func aRemovedPlaceStaysOnStoredActivities() {
        let h = harness(["Doctor"])
        away(h)
        h.engine.setAwayPlace(named: "Doctor")
        h.engine.closeTrackerPrompt()
        h.engine.removeAwayPlace("Doctor")
        #expect(awayItems(h).map(\.awayPlaceName) == ["Doctor"])
        #expect(awayItems(h).map(\.text) == ["Away · Doctor"])
    }

    @Test func theNextPromptCarriesAnAddedPlace() {
        let h = harness()
        h.engine.addAwayPlace("Doctor")
        away(h)
        #expect(state(h)?.places == ["Doctor"])
    }
}
