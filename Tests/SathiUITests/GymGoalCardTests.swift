import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Gym goal card")
struct GymGoalCardTests {
    private func harness(_ configure: @escaping (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness {
            $0.prefs.gym.enabled = true
            configure(&$0)
        }
    }

    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(GymGoalCard(), h).inspect()
    }

    @Test func cardShowsBothRowsAndEveryChip() throws {
        let sut = try card(harness())
        let texts = ["Sessions a day", "Each session"]
        for text in texts {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
        for label in ["1", "2", "3", "4", "5", "6", "7", "8", "2 min", "3 min", "5 min", "10 min", "15 min"] {
            #expect(throws: Never.self) { try sut.find(button: label) }
        }
    }

    @Test func theSavedChipsAreSelected() throws {
        let sut = try card(harness())
        #expect(try A11y.isSelected(sut.find(button: "4")))
        #expect(try !A11y.isSelected(sut.find(button: "6")))
        #expect(try A11y.isSelected(sut.find(button: "5 min")))
        #expect(try !A11y.isSelected(sut.find(button: "10 min")))
    }

    @Test func tappingASessionCountSavesIt() throws {
        let h = harness()
        try card(h).find(button: "6").tap()
        #expect(h.store.prefs.gym.sessionsPerDay == 6)
    }

    @Test func tappingASessionLengthSavesIt() throws {
        let h = harness()
        try card(h).find(button: "10 min").tap()
        #expect(h.store.prefs.gym.sessionMinutes == 10)
    }

    @Test func summaryShowsTheDailyGoal() throws {
        #expect(throws: Never.self) { try card(harness()).find(text: "Daily goal: 20 min · 4 × 5 min") }
        let other = try card(harness {
            $0.prefs.gym.sessionsPerDay = 6
            $0.prefs.gym.sessionMinutes = 10
        })
        #expect(throws: Never.self) { try other.find(text: "Daily goal: 60 min · 6 × 10 min") }
    }

    @Test func popupTimesSpreadEvenlyInsideWorkHours() throws {
        let times = [600, 720, 840, 960].map { Fmt.timeOfDay($0) }.joined(separator: ", ")
        #expect(throws: Never.self) { try card(harness()).find(text: "Popups at " + times) }
    }

    @Test func popupTimesFollowTheSessionCount() throws {
        let h = harness {
            $0.prefs.gym.sessionsPerDay = 2
            $0.prefs.gym.startMinutes = 8 * 60
            $0.prefs.gym.endMinutes = 16 * 60
        }
        let times = [600, 840].map { Fmt.timeOfDay($0) }.joined(separator: ", ")
        #expect(throws: Never.self) { try card(h).find(text: "Popups at " + times) }
    }
}
