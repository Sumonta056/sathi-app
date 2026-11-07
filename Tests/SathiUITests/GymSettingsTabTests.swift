import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Gym settings tab")
struct GymSettingsTabTests {
    private func harness(_ configure: @escaping (inout Persisted) -> Void = { _ in }) -> EngineHarness {
        EngineHarness {
            $0.prefs.gym.enabled = true
            configure(&$0)
        }
    }

    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(GymSettingsTab(), h).inspect()
    }

    private func texts(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    @Test func tabShowsHeroGoalRhythmIdeasAndThreeStrictnessCards() throws {
        let h = harness()
        let sut = try tab(h)
        let texts = [
            "SHOKTI · GYM", "Get up, little and often", "Shokti suggests a short move while you work.",
            "Sessions a day", "Each session", "Daily goal: 20 min · 4 × 5 min",
            "Work hours", "Popups spread evenly inside these hours.", "Work days",
            "+ Add idea", "Gentle", "Nudgy", "Strict", Strictness.strict.detail
        ]
        for text in texts {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
        #expect(throws: Never.self) { try Find.button(sut, label: "Gym reminders") }
        #expect(throws: Never.self) { try sut.find(GymGoalCard.self) }
        #expect(throws: Never.self) { try sut.find(GymIdeasCard.self) }
        #expect(sut.findAll(ViewType.TextField.self).isEmpty)
        for name in GymIdeas.defaults {
            #expect(throws: Never.self) { try sut.find(button: name) }
        }
    }

    @Test func sectionsAreInOrder() throws {
        let labels = ["DAILY GOAL", "RHYTHM", "DAYS OFF", "MY WORKOUT IDEAS", "IF I IGNORE SHOKTI"]
        let order = try texts(tab(harness())).filter { labels.contains($0) }
        #expect(order == labels)
    }

    @Test func gymTabHasNoIntervalRow() throws {
        let sut = try tab(harness())
        #expect(sut.findAll(IntervalRow.self).isEmpty)
        #expect(Find.lacks(sut, text: "Remind me every"))
        #expect(Find.lacks(sut, text: "Shokti sleeps outside these hours."))
        #expect(Find.lacks(sut, text: "MY 4 WORKOUTS"))
    }

    @Test func rhythmCardHasNoIntervalRow() throws {
        let sut = try hosted(GymRhythmCard(), harness()).inspect()
        #expect(sut.findAll(IntervalRow.self).isEmpty)
        #expect(throws: Never.self) { try sut.find(text: "Work hours") }
    }

    @Test func lastWorkDayCannotBeTurnedOff() throws {
        let h = harness { $0.prefs.gym.weekdays = [.wednesday] }
        try Find.button(tab(h), label: "Wednesday").tap()
        #expect(h.engine.data.prefs.gym.weekdays == [.wednesday])
        try Find.button(tab(h), label: "Friday").tap()
        #expect(h.store.prefs.gym.weekdays == [.wednesday, .friday])
    }

    @Test func strictCardSetsStrict() throws {
        let h = harness()
        try Find.button(tab(h), holding: "Strict").tap()
        #expect(h.store.prefs.gym.strictness == .strict)
    }

    @Test func storedStrictGymShowsStrictSelected() throws {
        let sut = try tab(harness { $0.prefs.gym.strictness = .strict })
        #expect(try A11y.isSelected(Find.button(sut, holding: "Strict")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Nudgy")))
    }

    @Test func nudgyCardSetsPersistent() throws {
        let h = harness()
        try Find.button(tab(h), holding: "Nudgy").tap()
        #expect(h.store.prefs.gym.strictness == .persistent)
    }
}
