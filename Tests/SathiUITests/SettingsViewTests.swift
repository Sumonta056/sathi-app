import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Settings")
struct SettingsViewTests {
    @Test func waterToggleTurnsRemindersOff() throws {
        let h = EngineHarness()
        let sut = SettingsView().environmentObject(h.engine)
        try sut.inspect().find(ViewType.Toggle.self) { try $0.labelView().text().string() == "Remind me to drink water" }.tap()
        #expect(!h.engine.data.prefs.water.enabled)
        #expect(h.store.prefs.water.enabled == false)
    }

    @Test func tryItButtonsTriggerReminders() throws {
        let h = EngineHarness()
        let sut = SettingsView().environmentObject(h.engine)
        try sut.inspect().find(button: "Show water reminder now").tap()
        #expect(h.engine.phase == .bubble(.water, .nudge))
    }

    @Test func strictnessDetailIsShown() throws {
        let h = EngineHarness()
        let sut = SettingsView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: Strictness.strict.detail) != nil)
    }

    @Test func intervalLabelIsHumanReadable() throws {
        let h = EngineHarness()
        let sut = SettingsView().environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "Every 2 hours") != nil)
    }

    @Test func timeSlotsCoverTheDayInHalfHours() {
        #expect(TimeSlots.all.count == 48)
        #expect(TimeSlots.all.first?.minutes == 0)
        #expect(TimeSlots.all.last?.minutes == 23 * 60 + 30)
    }
}
