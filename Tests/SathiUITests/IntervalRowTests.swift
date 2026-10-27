import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
final class MinutesBox {
    var value: Int
    init(_ value: Int) { self.value = value }
    var binding: Binding<Int> { Binding(get: { self.value }, set: { self.value = $0 }) }
}

@MainActor
@Suite("Interval row")
struct IntervalRowTests {
    static let labels = ["15 min", "30 min", "45 min", "60 min", "75 min", "90 min", "105 min", "120 min"]

    @Test func rowShowsTheLabelAndAllEightChips() throws {
        let box = MinutesBox(60)
        let sut = try IntervalRow(minutes: box.binding, accent: Night.text).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Remind me every") }
        for label in Self.labels {
            #expect(throws: Never.self) { try sut.find(button: label) }
        }
    }

    @Test func tappingAChipSetsTheMinutes() throws {
        let box = MinutesBox(60)
        try IntervalRow(minutes: box.binding, accent: Night.text).inspect().find(button: "45 min").tap()
        #expect(box.value == 45)
    }

    @Test func theSavedChipIsSelected() throws {
        let box = MinutesBox(105)
        let sut = try IntervalRow(minutes: box.binding, accent: Night.text).inspect()
        #expect(try A11y.isSelected(sut.find(button: "105 min")))
        #expect(try !A11y.isSelected(sut.find(button: "15 min")))
    }

    @Test(arguments: [HabitID.water, .meditation, .gym])
    func intervalTabsShowEveryChip(_ id: HabitID) throws {
        let h = settingsHarness()
        let sut = try settingsTab(id, h)
        #expect(throws: Never.self) { try sut.find(text: "Remind me every") }
        for label in Self.labels {
            #expect(throws: Never.self) { try sut.find(button: label) }
        }
    }

    @Test(arguments: [HabitID.water, .meditation, .gym])
    func tappingFortyFiveSetsThatHabitsInterval(_ id: HabitID) throws {
        let h = settingsHarness()
        try settingsTab(id, h).find(button: "45 min").tap()
        #expect(interval(id, h) == 45)
    }

    @Test func readingKeepsItsSetTime() throws {
        let sut = try hosted(ReadingSettingsTab(), settingsHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Remind me at") }
        #expect(Find.lacks(sut, text: "Remind me every"))
    }

    private func settingsHarness() -> EngineHarness {
        EngineHarness {
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
            $0.prefs.water.intervalMinutes = 120
            $0.prefs.meditation.intervalMinutes = 60
            $0.prefs.gym.intervalMinutes = 60
        }
    }

    private func settingsTab(_ id: HabitID, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        switch id {
        case .water: return try hosted(WaterSettingsTab(), h).inspect()
        case .meditation: return try hosted(MeditationSettingsTab(), h).inspect()
        case .gym: return try hosted(GymSettingsTab(), h).inspect()
        case .reading: return try hosted(ReadingSettingsTab(), h).inspect()
        }
    }

    private func interval(_ id: HabitID, _ h: EngineHarness) -> Int? {
        switch id {
        case .water: return h.engine.data.prefs.water.intervalMinutes
        case .meditation: return h.engine.data.prefs.meditation.intervalMinutes
        case .gym: return h.engine.data.prefs.gym.intervalMinutes
        case .reading: return nil
        }
    }
}
