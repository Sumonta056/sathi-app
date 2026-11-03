import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Time block settings page")
struct TimeBlockSettingsPageTests {
    private func selected(_ sut: InspectableView<some BaseViewType>, _ id: String) throws -> Bool {
        try A11y.isSelected(BlockSettings.control(sut, id))
    }

    @Test func showsEverySection() throws {
        let sut = try BlockSettings.page(BlockSettings.harness())
        for text in [
            Copywriter.blockSettingsTitle, Copywriter.blockSettingsDefaultCalendar, Copywriter.blockSettingsCalendarNote,
            Copywriter.blockSettingsDisplay, Copywriter.blockSettingsMenuBar, Copywriter.blockSettingsWidget,
            Copywriter.blockSettingsSound
        ] {
            #expect(throws: Never.self) { try sut.find(text: text) }
        }
    }

    @Test func listsEveryCalendarGroupedByAccount() throws {
        let h = BlockSettings.harness()
        h.calendarWriter.choices = [
            CalendarChoice(id: "a1", title: "Alpha", account: "Gmail", colorHex: 0x4285F4),
            CalendarChoice(id: "a2", title: "Beta", account: "Gmail", colorHex: 0xEA4335),
            CalendarChoice(id: "b1", title: "Gamma", account: "iCloud", colorHex: 0x34A853)
        ]
        h.engine.refreshCalendarAccess()
        let sut = try BlockSettings.page(h)
        for id in ["a1", "a2", "b1"] {
            #expect(BlockSettings.has(sut, "settings.block.calendar.\(id)"))
        }
        let order = BlockSettings.texts(sut)
        let gmail = try #require(order.firstIndex(of: "Gmail"))
        let alpha = try #require(order.firstIndex(of: "Alpha"))
        let beta = try #require(order.firstIndex(of: "Beta"))
        let icloud = try #require(order.firstIndex(of: "iCloud"))
        let gamma = try #require(order.firstIndex(of: "Gamma"))
        #expect(gmail < alpha && alpha < beta && beta < icloud && icloud < gamma)
    }

    @Test func withoutAPickTheMacOSDefaultIsSelected() throws {
        let h = BlockSettings.harness()
        h.calendarWriter.defaultID = "home"
        h.engine.refreshCalendarAccess()
        let sut = try BlockSettings.page(h)
        #expect(try selected(sut, "settings.block.calendar.home"))
        #expect(try !selected(sut, "settings.block.calendar.work"))
    }

    @Test func theSavedPickIsSelected() throws {
        let h = BlockSettings.harness { $0.prefs.timeBlock.defaultCalendarID = "work" }
        h.calendarWriter.defaultID = "home"
        let sut = try BlockSettings.page(h)
        #expect(try selected(sut, "settings.block.calendar.work"))
        #expect(try !selected(sut, "settings.block.calendar.home"))
    }

    @Test func tappingACalendarSetsTheDefaultCalendar() throws {
        let h = BlockSettings.harness()
        try BlockSettings.tap(BlockSettings.page(h), "settings.block.calendar.home")
        #expect(h.engine.data.prefs.timeBlock.defaultCalendarID == "home")
        #expect(h.engine.startCalendarID == "home")
    }

    @Test func menuBarIsSelectedByDefault() throws {
        let sut = try BlockSettings.page(BlockSettings.harness())
        #expect(try selected(sut, "settings.block.display.menuBar"))
        #expect(try !selected(sut, "settings.block.display.widget"))
    }

    @Test func cornerWidgetOptionSetsTheDisplay() throws {
        let h = BlockSettings.harness()
        try BlockSettings.tap(BlockSettings.page(h), "settings.block.display.widget")
        #expect(h.engine.data.prefs.timeBlock.display == .widget)
    }

    @Test func menuBarOptionSetsTheDisplayBack() throws {
        let h = BlockSettings.harness { $0.prefs.timeBlock.display = .widget }
        let sut = try BlockSettings.page(h)
        #expect(try selected(sut, "settings.block.display.widget"))
        try BlockSettings.tap(sut, "settings.block.display.menuBar")
        #expect(h.engine.data.prefs.timeBlock.display == .menuBar)
    }

    @Test func soundSwitchReflectsAndTogglesPlaysSound() throws {
        let h = BlockSettings.harness()
        let sut = try BlockSettings.page(h)
        #expect(try selected(sut, "settings.block.sound"))
        try BlockSettings.tap(sut, "settings.block.sound")
        #expect(!h.engine.data.prefs.timeBlock.playsSound)
        try BlockSettings.tap(BlockSettings.page(h), "settings.block.sound")
        #expect(h.engine.data.prefs.timeBlock.playsSound)
    }

    @Test func soundSwitchIsOffWhenSoundIsOff() throws {
        let h = BlockSettings.harness { $0.prefs.timeBlock.playsSound = false }
        #expect(try !selected(BlockSettings.page(h), "settings.block.sound"))
    }

    @Test func displayAndSoundStayAvailableWithoutCalendarAccess() throws {
        let h = BlockSettings.harness(access: .denied)
        let sut = try BlockSettings.page(h)
        try BlockSettings.tap(sut, "settings.block.display.widget")
        try BlockSettings.tap(sut, "settings.block.sound")
        #expect(h.engine.data.prefs.timeBlock.display == .widget)
        #expect(!h.engine.data.prefs.timeBlock.playsSound)
    }
}
