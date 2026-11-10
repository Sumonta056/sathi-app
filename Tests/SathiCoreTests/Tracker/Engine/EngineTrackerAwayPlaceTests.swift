import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker away place")
struct EngineTrackerAwayPlaceTests {
    private func away(minutes: Double, places: [String] = []) -> EngineHarness {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.awayPlaces = places }
        h.start("Write spec", minutes: 30)
        h.clock.advance(minutes: 20)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: minutes)
        h.engine.presenceChanged(.unlocked)
        return h
    }

    private func awayItems(_ h: EngineHarness) -> [Activity] { h.saved.filter { $0.kind == .away } }

    private func state(_ h: EngineHarness) -> TrackerPromptState? { h.engine.trackerPromptState(.welcomeBack) }

    @Test func aShortAwayStoresNoItemAndStillShowsWelcomeBack() {
        let h = away(minutes: 0.5)
        #expect(h.promptKind == .welcomeBack)
        #expect(awayItems(h).isEmpty)
        #expect(state(h)?.away?.place == nil)
    }

    @Test func aPlaceShowsInThePromptWhenNoAwayItemIsStored() {
        let h = away(minutes: 0.5)
        h.engine.setAwayPlace(.lunch)
        #expect(state(h)?.away?.place == .lunch)
        #expect(state(h)?.away?.placeName == nil)
        #expect(awayItems(h).isEmpty)
    }

    @Test func aNamedPlaceShowsInThePromptWhenNoAwayItemIsStored() {
        let h = away(minutes: 0.5, places: ["Doctor"])
        h.engine.setAwayPlace(named: "Doctor")
        #expect(state(h)?.away?.place == .other)
        #expect(state(h)?.away?.placeName == "Doctor")
        #expect(awayItems(h).isEmpty)
    }

    @Test func aPlaceNamesTheStoredAwayItemAndThePrompt() {
        let h = away(minutes: 30)
        h.engine.setAwayPlace(.lunch)
        #expect(awayItems(h).map(\.awayPlace) == [.lunch])
        #expect(awayItems(h).map(\.text) == ["Away · Lunch"])
        #expect(awayItems(h).map(\.awayPlaceName) == [nil])
        #expect(state(h)?.away?.place == .lunch)
    }

    @Test func aNamedPlaceIsOtherWithTheNameOnTheStoredItem() {
        let h = away(minutes: 30, places: ["Doctor"])
        h.engine.setAwayPlace(named: "Doctor")
        #expect(awayItems(h).map(\.awayPlace) == [.other])
        #expect(awayItems(h).map(\.awayPlaceName) == ["Doctor"])
        #expect(awayItems(h).map(\.text) == ["Away · Doctor"])
        #expect(awayItems(h).map(\.start) == [wed(10, 20)])
        #expect(awayItems(h).map(\.end) == [wed(10, 50)])
        #expect(state(h)?.away?.place == .other)
        #expect(state(h)?.away?.placeName == "Doctor")
    }

    @Test func aBuiltInPickAfterANamedPickClearsTheName() {
        let h = away(minutes: 30, places: ["Doctor"])
        h.engine.setAwayPlace(named: "Doctor")
        h.engine.setAwayPlace(.walk)
        #expect(awayItems(h).map(\.awayPlace) == [.walk])
        #expect(awayItems(h).map(\.awayPlaceName) == [nil])
        #expect(awayItems(h).map(\.text) == ["Away · Walk"])
        #expect(state(h)?.away?.place == .walk)
        #expect(state(h)?.away?.placeName == nil)
    }

    @Test func otherAfterANamedPickClearsTheNameToo() {
        let h = away(minutes: 30, places: ["Doctor"])
        h.engine.setAwayPlace(named: "Doctor")
        h.engine.setAwayPlace(.other)
        #expect(awayItems(h).map(\.awayPlaceName) == [nil])
        #expect(awayItems(h).map(\.text) == ["Away · Other"])
        #expect(state(h)?.away?.placeName == nil)
    }

    @Test func aNamedPickAfterABuiltInPickReplacesIt() {
        let h = away(minutes: 30, places: ["Doctor", "Gym"])
        h.engine.setAwayPlace(.lunch)
        h.engine.setAwayPlace(named: "Gym")
        #expect(awayItems(h).map(\.text) == ["Away · Gym"])
        #expect(awayItems(h).count == 1)
        #expect(state(h)?.away?.placeName == "Gym")
    }

    @Test func aFreshAwayStartsWithNoPlaceAndNoName() {
        let h = away(minutes: 30, places: ["Doctor"])
        h.engine.setAwayPlace(named: "Doctor")
        h.engine.closeTrackerPrompt()
        h.clock.advance(minutes: 5)
        h.engine.presenceChanged(.locked)
        h.clock.advance(minutes: 10)
        h.engine.presenceChanged(.unlocked)
        #expect(state(h)?.away?.place == nil)
        #expect(state(h)?.away?.placeName == nil)
        #expect(awayItems(h).map(\.text) == ["Away · Doctor", "Away"])
    }

    @Test func thePromptStateCarriesTheSavedPlaces() {
        let h = away(minutes: 30, places: ["Doctor", "Gym"])
        #expect(state(h)?.places == ["Doctor", "Gym"])
        #expect(h.engine.awayPlaces == ["Doctor", "Gym"])
    }

    @Test func thePromptStateHasNoPlacesByDefault() {
        let h = away(minutes: 30)
        #expect(state(h)?.places == [])
        #expect(h.engine.awayPlaces == [])
    }

    @Test func thePickPlaceActionSetsThePlace() {
        let h = away(minutes: 0.5)
        state(h)?.actions.pickPlace(.commute)
        #expect(state(h)?.away?.place == .commute)
    }

    @Test func thePickPlaceNameActionSetsTheNamedPlace() {
        let h = away(minutes: 30, places: ["Doctor"])
        state(h)?.actions.pickPlaceName("Doctor")
        #expect(awayItems(h).map(\.text) == ["Away · Doctor"])
        #expect(state(h)?.away?.placeName == "Doctor")
    }

    @Test func theAddPlaceActionSavesAndPicksThePlace() {
        let h = away(minutes: 30)
        state(h)?.actions.addPlace("Dentist")
        #expect(h.store.prefs.tracker.awayPlaces == ["Dentist"])
        #expect(state(h)?.places == ["Dentist"])
        #expect(state(h)?.away?.placeName == "Dentist")
        #expect(awayItems(h).map(\.text) == ["Away · Dentist"])
    }
}
