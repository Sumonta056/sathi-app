import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar headers look")
struct CalendarHeaderLookTests {
    typealias Fix = CalendarSplitViewFixtures

    private var tuesday: DayKey { DayKey(Fix.z.date(2026, 11, 17, 12), calendar: Fix.cal) }

    private func headers(today: DayKey) throws -> InspectableView<ViewType.ClassifiedView> {
        try CalendarWeekHeaders(days: [Fix.monday, tuesday], today: today, calendar: Fix.cal, column: 200).inspect()
    }

    @Test func todayShowsItsDayNumberInARedCircle() throws {
        let sut = try headers(today: tuesday)
        let number = try sut.find(viewWithAccessibilityIdentifier: "calendar.week.todayNumber")
        #expect(throws: Never.self) { try number.find(text: "17") }
        #expect(throws: Never.self) { try sut.find(text: "Tue") }
        #expect(try sut.findAll(ViewType.Text.self).filter { try $0.string() == "Nov" }.count == 2)
    }

    @Test func otherDaysHaveNoCircle() throws {
        let sut = try headers(today: DayKey(Fix.z.date(2026, 11, 20, 12), calendar: Fix.cal))
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "calendar.week.todayNumber")) == nil)
        #expect(throws: Never.self) { try sut.find(text: "16") }
    }

    @Test func dayHeaderSplitsTheBoldWordFromTheRest() {
        #expect(CalendarDayHeader.parts("Actual · 2h 30m") == ("Actual", " · 2h 30m"))
        #expect(CalendarDayHeader.parts("Plan · 3 events") == ("Plan", " · 3 events"))
        #expect(CalendarDayHeader.parts("Plan") == ("Plan", ""))
    }
}
