import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Menu bar")
struct MenuBarTests {
    @Test func panelShowsARowForEachEnabledHabit() throws {
        let h = EngineHarness()
        let sut = MenuPanel().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "Sathi") != nil)
        #expect(try sut.inspect().findAll(HabitRow.self).count == 2)
    }

    @Test func disabledHabitHasNoRow() throws {
        let h = EngineHarness { $0.prefs.readingEnabled = false }
        let sut = MenuPanel().environmentObject(h.engine)
        #expect(try sut.inspect().findAll(HabitRow.self).count == 1)
    }

    @Test func pauseItemPausesReminders() throws {
        let h = EngineHarness()
        let sut = MenuPanel().environmentObject(h.engine)
        try sut.inspect().find(text: "Pause reminders for 1 hour").find(ViewType.Button.self, relation: .parent).tap()
        #expect(h.engine.pausedUntil != nil)
        #expect(try sut.inspect().find(text: "Resume reminders") != nil)
    }

    @Test func settingsItemOpensSettings() throws {
        let h = EngineHarness()
        let sut = MenuPanel().environmentObject(h.engine)
        try sut.inspect().find(text: "Settings…").find(ViewType.Button.self, relation: .parent).tap()
        #expect(h.presenter.calls.last == .showSettings)
    }

    @Test func waterRowShowsPillAndLogsAGlass() throws {
        let h = EngineHarness()
        let sut = HabitRow(id: .water).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "in 2h 0m") != nil)
        try sut.inspect().find(button: "+1 glass").tap()
        #expect(h.engine.data.drinks.last?.glasses == 1)
    }

    @Test func readingRowStartsASession() throws {
        let h = EngineHarness()
        let sut = HabitRow(id: .reading).environmentObject(h.engine)
        try sut.inspect().find(button: "Read now").tap()
        #expect(h.engine.phase == .session)
    }

    @Test func statusLabelShowsTheStatusText() throws {
        let h = EngineHarness()
        let sut = StatusLabel(status: h.engine.status)
        #expect(try sut.inspect().find(text: "2h 0m") != nil)
    }

    @Test func statusIconIsCachedPerLevel() {
        #expect(StatusIcon.image(level: 0.5) === StatusIcon.image(level: 0.5))
        #expect(StatusIcon.image(level: 0.5).isTemplate)
    }
}
