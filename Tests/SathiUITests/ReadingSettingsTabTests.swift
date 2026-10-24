import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reading settings tab")
struct ReadingSettingsTabTests {
    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(ReadingSettingsTab(), h).inspect()
    }

    @Test func showsTheHero() throws {
        let sut = try tab(EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: "BOI · READING") }
        #expect(throws: Never.self) { try sut.find(text: "A few pages before bed") }
    }

    @Test func saturdayChipTurnsSaturdayOff() throws {
        let h = EngineHarness()
        try Find.button(tab(h), label: "Saturday").tap()
        #expect(h.engine.data.prefs.reading.weekdays == Set(Weekday.allCases).subtracting([.saturday]))
    }

    @Test func dayChipTurnsAnOffDayOn() throws {
        let h = EngineHarness { $0.prefs.reading.weekdays = [.monday] }
        try Find.button(tab(h), label: "Sunday").tap()
        #expect(h.engine.data.prefs.reading.weekdays == [.monday, .sunday])
    }

    @Test func tapOnTheOnlySelectedDayKeepsIt() throws {
        let h = EngineHarness { $0.prefs.reading.weekdays = [.monday] }
        try Find.button(tab(h), label: "Monday").tap()
        #expect(h.engine.data.prefs.reading.weekdays == [.monday])
    }

    @Test func selectedDaysHaveTheSelectedTrait() throws {
        let sut = try tab(EngineHarness { $0.prefs.reading.weekdays = [.monday, .friday] })
        #expect(try A11y.isSelected(Find.button(sut, label: "Friday")))
        #expect(try !A11y.isSelected(Find.button(sut, label: "Saturday")))
    }

    @Test func focusScreenSetsTheStyle() throws {
        let h = EngineHarness()
        try Find.button(tab(h), holding: "Focus screen").tap()
        #expect(h.engine.data.prefs.reading.reminderStyle == .focus)
    }

    @Test func cornerPopupSetsTheStyle() throws {
        let h = EngineHarness { $0.prefs.reading.reminderStyle = .focus }
        try Find.button(tab(h), holding: "Corner popup").tap()
        #expect(h.engine.data.prefs.reading.reminderStyle == .corner)
    }

    @Test func sessionChipSetsTheLength() throws {
        let h = EngineHarness()
        try tab(h).find(button: "30 min").tap()
        #expect(h.engine.data.prefs.reading.sessionMinutes == 30)
    }

    @Test func gentleCardSetsFriendly() throws {
        let h = EngineHarness()
        try Find.button(tab(h), holding: "Gentle").tap()
        #expect(h.engine.data.prefs.reading.strictness == .friendly)
    }
}
