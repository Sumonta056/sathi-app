import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Settings sidebar")
struct SettingsSidebarTests {
    private func sidebar(_ h: EngineHarness, _ tab: Box<SettingsTab> = Box(.general)) -> some View {
        SettingsSidebar(tab: tab.binding).environmentObject(h.engine)
    }

    @Test func showsEveryNavEntry() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        for text in ["Sathi", "General", "Water", "Reading", "Meditation", "Add a buddy", "Open reports"] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
    }

    @Test func meditationRowShowsNewBadge() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "NEW") }
    }

    @Test func readingSwitchTurnsReadingOff() throws {
        let h = EngineHarness()
        try Find.button(sidebar(h).inspect(), label: "Reading reminders").tap()
        #expect(!h.engine.data.prefs.reading.enabled)
        #expect(h.store.prefs.reading.enabled == false)
    }

    @Test func meditationSwitchTurnsMeditationOn() throws {
        let h = EngineHarness()
        try Find.button(sidebar(h).inspect(), label: "Meditation reminders").tap()
        #expect(h.engine.data.prefs.meditation.enabled)
    }

    @Test func waterNavSelectsTheWaterTab() throws {
        let tab = Box<SettingsTab>(.general)
        try Find.button(sidebar(EngineHarness(), tab).inspect(), holding: "Water").tap()
        #expect(tab.value == .habit(.water))
    }

    @Test func addBuddyNavSelectsTheAddBuddyTab() throws {
        let tab = Box<SettingsTab>(.general)
        try Find.button(sidebar(EngineHarness(), tab).inspect(), holding: "Add a buddy").tap()
        #expect(tab.value == .addBuddy)
    }

    @Test func generalNavSelectsTheGeneralTab() throws {
        let tab = Box<SettingsTab>(.habit(.reading))
        try Find.button(sidebar(EngineHarness(), tab).inspect(), holding: "General").tap()
        #expect(tab.value == .general)
    }

    @Test func selectedNavButtonHasTheSelectedTrait() throws {
        let sut = try sidebar(EngineHarness(), Box(.habit(.water))).inspect()
        #expect(try A11y.isSelected(Find.button(sut, holding: "Water")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "General")))
    }

    @Test func openReportsIsDisabledAndSaysSoon() throws {
        let sut = try sidebar(EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Soon") }
        let reports = try sut.find(text: "Open reports")
        let button = try? reports.find(ViewType.Button.self, relation: .parent)
        #expect(button == nil || button?.isDisabled() == true)
    }

    @Test func waterTabShowsItsHero() throws {
        let sut = try hosted(WaterSettingsTab(), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Small sips, all day long") }
        #expect(throws: Never.self) { try sut.find(text: "FOTA · WATER") }
    }

    @Test func addBuddyTabShowsFourComingSoonBuddies() throws {
        let sut = try AddBuddyTab().inspect()
        for text in ["Add a buddy", "Stretch", "Eye break", "Walk", "Posture", "Loosen up every hour."] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
        let soon = sut.findAll(ViewType.Button.self).filter { (try? $0.labelView().find(text: "Soon")) != nil }
        #expect(soon.count == 4)
        #expect(soon.allSatisfy { $0.isDisabled() })
    }

    @Test func rootShowsSidebarAndGeneralTabFirst() throws {
        let sut = try hosted(SettingsView(), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(SettingsSidebar.self) }
        #expect(throws: Never.self) { try sut.find(text: "Hi there") }
        #expect(Find.lacks(sut, text: "Small sips, all day long"))
    }
}
