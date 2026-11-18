import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Calendar week side panel")
struct CalendarWeekSidePanelTests {
    private func decode(_ json: String) throws -> CalendarPagePrefs {
        try JSONDecoder().decode(CalendarPagePrefs.self, from: Data(json.utf8))
    }

    @Test func weekPanelIsHiddenByDefault() {
        #expect(CalendarPagePrefs().sidePanelShownWeek == false)
        #expect(CalendarPagePrefs().sidePanelShown == true)
    }

    @Test func oldCalendarPageWithoutTheWeekKeyHidesTheWeekPanelAndKeepsTheRest() throws {
        let value = try decode(#"{"isOn":true,"sidePanelShown":false,"lastCalendarID":"work","rowMinutes":30}"#)
        #expect(value.sidePanelShownWeek == false)
        #expect(value.sidePanelShown == false)
        #expect(value.isOn == true)
        #expect(value.lastCalendarID == "work")
        #expect(value.rowMinutes == 30)
    }

    @Test func savedShownWeekPanelStaysShown() throws {
        #expect(try decode(#"{"sidePanelShownWeek":true}"#).sidePanelShownWeek == true)
    }

    @Test func weekKeyWrongTypeGivesHiddenAndKeepsOthers() throws {
        let value = try decode(#"{"sidePanelShownWeek":"yes","isOn":true,"sidePanelShown":false}"#)
        #expect(value.sidePanelShownWeek == false)
        #expect(value.isOn == true)
        #expect(value.sidePanelShown == false)
    }

    @Test func roundTripKeepsTheWeekPanel() throws {
        var value = CalendarPagePrefs()
        value.sidePanelShownWeek = true
        value.sidePanelShown = false
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(CalendarPagePrefs.self, from: data) == value)
    }

    @Test func oldPrefsFileOnDiskLoadsTheWeekPanelHidden() throws {
        let base = makeTempFolder()
        let url = base.appendingPathComponent("prefs.json")
        try writeText(#"{"schemaVersion":1,"value":{"calendarPage":{"isOn":true,"sidePanelShown":true}}}"#, to: url)
        var expected = Prefs()
        expected.calendarPage.isOn = true
        #expect(FileStateStore(base: base).loadPrefs() == expected)
    }

    @Test(arguments: ReportRange.allCases)
    func eachViewReadsItsOwnChoice(_ kind: ReportRange) {
        var value = CalendarPagePrefs()
        value.sidePanelShown = true
        value.sidePanelShownWeek = false
        #expect(value.sidePanelShown(for: kind) == (kind != .week))
    }

    @MainActor @Test func togglingInWeekChangesOnlyTheWeekChoice() {
        let h = EngineHarness()
        h.engine.setCalendarSidePanelShown(true, for: .week)
        #expect(h.store.prefs.calendarPage.sidePanelShownWeek == true)
        #expect(h.store.prefs.calendarPage.sidePanelShown == true)
        h.engine.setCalendarSidePanelShown(false, for: .week)
        #expect(h.store.prefs.calendarPage.sidePanelShownWeek == false)
        #expect(h.store.prefs.calendarPage.sidePanelShown == true)
    }

    @MainActor @Test(arguments: [ReportRange.day, .month])
    func togglingInDayOrMonthChangesOnlyTheSharedChoice(_ kind: ReportRange) {
        let h = EngineHarness()
        h.engine.setCalendarSidePanelShown(false, for: kind)
        #expect(h.store.prefs.calendarPage.sidePanelShown == false)
        #expect(h.store.prefs.calendarPage.sidePanelShownWeek == false)
        h.engine.setCalendarSidePanelShown(true, for: kind)
        #expect(h.store.prefs.calendarPage.sidePanelShown == true)
        #expect(h.store.prefs.calendarPage.sidePanelShownWeek == false)
    }
}
