import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Habit card")
struct HabitCardTests {
    private func card(_ id: HabitID, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(HabitCard(id: id), h).inspect()
    }

    @Test func waterCardShowsNameAndPill() throws {
        let h = EngineHarness()
        let sut = try card(.water, h)
        #expect(throws: Never.self) { try sut.find(text: "Water") }
        #expect(throws: Never.self) { try sut.find(text: "in 2h 0m") }
        #expect(throws: Never.self) { try sut.find(text: h.engine.pill(.water)) }
    }

    @Test func waterCardShowsTheGoalText() throws {
        let h = EngineHarness()
        h.engine.logWater(1)
        h.engine.logWater(1)
        let sut = try card(.water, h)
        #expect(throws: Never.self) { try sut.find(text: "2") }
        #expect(throws: Never.self) { try sut.find(text: "of 8 glasses") }
    }

    @Test func plusOneGlassLogsAGlass() throws {
        let h = EngineHarness()
        try MenuFind.control(card(.water, h), "+1 glass").tap()
        #expect(h.engine.glassesToday == 1)
        #expect(h.engine.data.events.last?.amount == 1)
    }

    @Test func readNowStartsReading() throws {
        let h = EngineHarness()
        try MenuFind.control(card(.reading, h), "Read now").tap()
        #expect(h.engine.phase == .session(.reading))
    }

    @Test func breatheStartsMeditation() throws {
        let h = EngineHarness { $0.prefs.meditation.enabled = true }
        try MenuFind.control(card(.meditation, h), "Breathe").tap()
        #expect(h.engine.phase == .session(.meditation))
    }

    @Test func waterRingShowsAQuarterAfterTwoOfEight() throws {
        let h = EngineHarness()
        h.engine.logWater(1)
        h.engine.logWater(1)
        #expect(try MenuFind.accessibilityValue(card(.water, h), label: "Water progress") == "25%")
    }

    @Test func readingRingIsLabelledWithTheHabitName() throws {
        let h = EngineHarness()
        #expect(try MenuFind.accessibilityValue(card(.reading, h), label: "Reading progress") == "0%")
    }

    @Test func ringClampsAboveFull() throws {
        let sut = try ProgressRing(progress: 1.4, accent: Night.water).inspect()
        #expect(MenuFind.accessibilityValues(sut).contains("100%"))
        #expect(!MenuFind.accessibilityValues(sut).contains("140%"))
    }

    @Test func ringClampsBelowEmpty() throws {
        let sut = try ProgressRing(progress: -0.2, accent: Night.water).inspect()
        #expect(MenuFind.accessibilityValues(sut).contains("0%"))
        #expect(!MenuFind.accessibilityValues(sut).contains("-20%"))
    }

    @Test func ringShowsAPartialPercent() throws {
        let sut = try ProgressRing(progress: 0.5, accent: Night.water).inspect()
        #expect(MenuFind.accessibilityValues(sut).contains("50%"))
    }

    @Test func sleepingRowNamesTheHabit() throws {
        let sut = try hosted(SleepingRow(id: .meditation), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Meditation is sleeping") }
    }

    @Test func sleepingRowTurnsTheHabitOn() throws {
        let h = EngineHarness { $0.prefs.reading.enabled = false }
        try MenuFind.control(hosted(SleepingRow(id: .reading), h).inspect(), "Turn on").tap()
        #expect(h.engine.data.prefs.reading.enabled)
    }

    @Test func menuIsWiderForTheCards() {
        #expect(UIMetrics.menuWidth == 380)
    }

    @Test(arguments: HabitID.allCases)
    func nameAndPillNeverWrap(_ id: HabitID) throws {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) { $0.prefs.meditation.enabled = true }
        let sut = try card(id, h)
        let texts = sut.findAll(ViewType.Text.self) { try [id.name, h.engine.pill(id)].contains($0.string()) }
        #expect(!texts.isEmpty)
        for text in texts {
            #expect(try text.lineLimit() == 1)
        }
    }
}
