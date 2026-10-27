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

    @Test func tabShowsHeroRhythmWorkoutsAndThreeStrictnessCards() throws {
        let sut = try tab(harness())
        let texts = [
            "SHOKTI · GYM", "Get up, little and often", "Shokti suggests a short move while you work.",
            "RHYTHM", "Remind me every", "Work hours", "Shokti sleeps outside these hours.", "Work days",
            "MY 4 WORKOUTS", "1", "2", "3", "4",
            "IF I IGNORE SHOKTI", "Gentle", "Nudgy", "Strict", Strictness.strict.detail
        ]
        for text in texts {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
        #expect(throws: Never.self) { try Find.button(sut, label: "Gym reminders") }
        #expect(sut.findAll(ViewType.TextField.self).count == Limits.gymWorkoutCount)
    }

    @Test func intervalChipsAreFortyFiveSixtyNinety() throws {
        let h = harness()
        let sut = try tab(h)
        for label in ["45 min", "60 min", "90 min"] {
            #expect(throws: Never.self) { try sut.find(button: label) }
        }
        #expect(try A11y.isSelected(sut.find(button: "60 min")))
        try sut.find(button: "90 min").tap()
        #expect(h.store.prefs.gym.intervalMinutes == 90)
    }

    @Test func editingANameSavesACleanedName() {
        let h = harness()
        h.engine.gymWorkoutName(at: 1).wrappedValue = String(repeating: "a", count: 60)
        #expect(h.store.prefs.gym.workouts[1].name.count == Limits.gymNameMaxLength)
        #expect(h.engine.gymWorkoutName(at: 1).wrappedValue == String(repeating: "a", count: 40))
    }

    @Test func clearingANameSavesTheDefaultName() {
        let h = harness { $0.prefs.gym.workouts[0].name = "Jumping jacks" }
        h.engine.gymWorkoutName(at: 0).wrappedValue = ""
        h.engine.commitGymWorkoutNames()
        #expect(h.store.prefs.gym.workouts[0].name == "Neck and shoulder stretch")
    }

    @Test func typingKeepsSpacesBetweenWords() {
        let h = harness()
        h.engine.gymWorkoutName(at: 1).wrappedValue = "Jumping "
        #expect(h.engine.gymWorkoutName(at: 1).wrappedValue == "Jumping ")
        h.engine.gymWorkoutName(at: 1).wrappedValue = "Jumping jacks"
        #expect(h.store.prefs.gym.workouts[1].name == "Jumping jacks")
    }

    @Test func workoutsCardShowsTheOrderNote() throws {
        let sut = try tab(harness())
        #expect(throws: Never.self) { try sut.find(text: "Shokti uses them in order: 1 → 2 → 3 → 4.") }
    }

    @Test func minutesChipSavesTheChoice() throws {
        let h = harness()
        h.engine.gymWorkoutMinutes(at: 2).wrappedValue = 10
        #expect(h.store.prefs.gym.workouts[2].minutes == 10)
        let sut = try tab(h)
        try Find.button(sut, label: "1 min", near: "4").tap()
        #expect(h.store.prefs.gym.workouts[3].minutes == 1)
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
