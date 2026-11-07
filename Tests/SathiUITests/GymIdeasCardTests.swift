import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Gym ideas card")
struct GymIdeasCardTests {
    private func harness(ideas: [String] = GymIdeas.defaults) -> EngineHarness {
        EngineHarness {
            $0.prefs.gym.enabled = true
            $0.prefs.gym.ideas = ideas
        }
    }

    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(GymIdeasCard(), h).inspect()
    }

    private func eight() -> [String] {
        (1 ... 8).map { "Move \($0)" }
    }

    @Test func oneRowPerIdeaWithANumberedPlaceholder() throws {
        let sut = try card(harness())
        #expect(sut.findAll(GymIdeaRow.self).count == 4)
        for n in 1 ... 4 {
            #expect(throws: Never.self) { try lazyField(sut, "Idea \(n)") }
            #expect(throws: Never.self) { try Find.button(sut, label: "Remove idea \(n)") }
        }
        #expect(throws: Never.self) { try sut.find(text: "Short walk") }
    }

    @Test func removeTakesOutThatIdea() throws {
        let h = harness()
        try Find.button(card(h), label: "Remove idea 2").tap()
        #expect(h.store.prefs.gym.ideas == ["Neck and shoulder stretch", "10 squats", "Wall push-ups"])
    }

    @Test func theLastIdeaCannotBeRemoved() throws {
        let sut = try card(harness(ideas: ["Plank"]))
        #expect(try Find.button(sut, label: "Remove idea 1").isDisabled())
    }

    @Test func removeIsOnWhileMoreThanOneIdeaIsLeft() throws {
        let sut = try card(harness(ideas: ["Plank", "Squats"]))
        #expect(try !Find.button(sut, label: "Remove idea 1").isDisabled())
    }

    @Test func addIdeaAddsABlankRow() throws {
        let h = harness()
        try Find.button(card(h), holding: "+ Add idea").tap()
        #expect(h.engine.data.prefs.gym.ideas == GymIdeas.defaults + [""])
        #expect(try card(h).findAll(GymIdeaRow.self).count == 5)
    }

    @Test func addIdeaIsOffAtEightIdeas() throws {
        let sut = try card(harness(ideas: eight()))
        #expect(sut.findAll(GymIdeaRow.self).count == 8)
        #expect(try Find.button(sut, holding: "+ Add idea").isDisabled())
    }

    @Test func addIdeaIsOnBelowEightIdeas() throws {
        let sut = try card(harness(ideas: Array(eight().prefix(7))))
        #expect(try !Find.button(sut, holding: "+ Add idea").isDisabled())
    }
}

@MainActor
@Suite("Gym idea bindings")
struct GymIdeaBindingTests {
    private func harness(ideas: [String] = GymIdeas.defaults) -> EngineHarness {
        EngineHarness {
            $0.prefs.gym.enabled = true
            $0.prefs.gym.ideas = ideas
        }
    }

    @Test func editingANameSavesItCutToTheMaxLength() {
        let h = harness()
        h.engine.gymIdeaName(at: 1).wrappedValue = String(repeating: "a", count: 60)
        #expect(h.store.prefs.gym.ideas[1] == String(repeating: "a", count: Limits.gymNameMaxLength))
        #expect(h.engine.gymIdeaName(at: 1).wrappedValue == String(repeating: "a", count: 40))
    }

    @Test func typingKeepsSpacesBetweenWords() {
        let h = harness()
        h.engine.gymIdeaName(at: 1).wrappedValue = "Jumping "
        #expect(h.engine.gymIdeaName(at: 1).wrappedValue == "Jumping ")
        h.engine.gymIdeaName(at: 1).wrappedValue = "Jumping jacks"
        #expect(h.store.prefs.gym.ideas[1] == "Jumping jacks")
    }

    @Test func aRowOutsideTheListReadsBlank() {
        #expect(harness().engine.gymIdeaName(at: 9).wrappedValue == "")
    }

    @Test func addGymIdeaAppendsABlankName() {
        let h = harness(ideas: ["Plank"])
        h.engine.addGymIdea()
        #expect(h.store.prefs.gym.ideas == ["Plank", ""])
    }

    @Test func addGymIdeaStopsAtTheMax() {
        let full = (1 ... Limits.gymIdeasMax).map { "Move \($0)" }
        let h = harness(ideas: full)
        h.engine.addGymIdea()
        #expect(h.engine.data.prefs.gym.ideas == full)
    }

    @Test func removeGymIdeaDropsThatRow() {
        let h = harness(ideas: ["Plank", "Squats", "Lunges"])
        h.engine.removeGymIdea(at: 0)
        #expect(h.store.prefs.gym.ideas == ["Squats", "Lunges"])
    }

    @Test func removeGymIdeaKeepsTheLastIdea() {
        let h = harness(ideas: ["Plank"])
        h.engine.removeGymIdea(at: 0)
        #expect(h.engine.data.prefs.gym.ideas == ["Plank"])
    }

    @Test func commitDropsBlankNames() {
        let h = harness(ideas: ["Plank", "", "  ", "Squats"])
        h.engine.commitGymIdeas()
        #expect(h.store.prefs.gym.ideas == ["Plank", "Squats"])
    }

    @Test func commitWithOnlyBlankNamesRestoresTheDefaults() {
        let h = harness(ideas: ["Plank"])
        h.engine.gymIdeaName(at: 0).wrappedValue = " "
        h.engine.commitGymIdeas()
        #expect(h.store.prefs.gym.ideas == GymIdeas.defaults)
    }
}
