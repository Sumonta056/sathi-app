import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar shown list")
struct CalendarShownListTests {
    private func list(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(CalendarShownList(), h).inspect()
    }

    @Test func listsEveryCalendarGroupedByAccount() throws {
        let sut = try list(EngineHarness())
        for line in ["Shown calendars", "GMAIL", "Gmail Work", "ICLOUD", "Home"] {
            #expect(throws: Never.self) { try sut.find(text: line) }
        }
    }

    @Test func aTapOnHomeHidesHome() throws {
        let h = EngineHarness()
        try Find.button(list(h), holding: "Home").tap()
        #expect(h.engine.data.prefs.calendarPage.hiddenCalendarIDs == ["home"])
    }

    @Test func aTapOnAHiddenCalendarShowsItAgain() throws {
        let h = EngineHarness { $0.prefs.calendarPage.hiddenCalendarIDs = ["home"] }
        try Find.button(list(h), holding: "Home").tap()
        #expect(h.engine.data.prefs.calendarPage.hiddenCalendarIDs.isEmpty)
    }

    @Test func aHiddenCalendarHasAnEmptyBox() throws {
        let h = EngineHarness { $0.prefs.calendarPage.hiddenCalendarIDs = ["home"] }
        let sut = try list(h)
        #expect(try !sut.find(viewWithAccessibilityIdentifier: "calendar.shown.home").accessibilityTraits().contains(.isSelected))
        #expect(try sut.find(viewWithAccessibilityIdentifier: "calendar.shown.work").accessibilityTraits().contains(.isSelected))
    }
}
