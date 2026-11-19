import Foundation
@testable import SathiCore
import Testing

@Suite("Copywriter calendar Day view")
struct CopywriterCalendarDayTests {
    @Test(arguments: [
        (TimeInterval(6 * 3600 + 31 * 60), "Actual · 6h 31m"),
        (TimeInterval(45 * 60), "Actual · 45m"),
        (TimeInterval(2 * 3600), "Actual · 2h"),
        (TimeInterval(0), "Actual · 0m")
    ])
    func actualShowsTheTrackedLength(seconds: TimeInterval, text: String) {
        #expect(Copywriter.calendarDayActual(seconds) == text)
    }

    @Test(arguments: [(3, "Plan · 3 events"), (1, "Plan · 1 event"), (0, "Plan · 0 events")])
    func planCountsTheEvents(count: Int, text: String) {
        #expect(Copywriter.calendarDayPlan(count) == text)
    }

    @Test func doneDuringNamesTheCount() {
        #expect(Copywriter.calendarDayDoneDuring(1) == "1 done during")
        #expect(Copywriter.calendarDayDoneDuring(4) == "4 done during")
    }

    @Test func calendarTagsMatchTheActivitiesPage() {
        #expect(Copywriter.calendarDayInCalendar == "Calendar")
        #expect(Copywriter.calendarDayNotInCalendar == "Not in calendar")
    }

    @Test func editLabelNamesTheCard() {
        #expect(Copywriter.calendarDayEditLabel("Code review") == "Edit Code review")
    }
}
