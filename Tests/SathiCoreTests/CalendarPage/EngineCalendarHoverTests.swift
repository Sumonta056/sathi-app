import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine builds the calendar hover card info")
struct EngineCalendarHoverTests {
    private func hover(_ e: CalendarEventInfo) -> CalendarHoverInfo? {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([e])
        guard let block = h.pageDay.blocks.first(where: { $0.title == e.title }) else { return nil }
        return h.engine.calendarHoverInfo(CalendarPlacedBlock(block: block, lane: 0, lanes: 1))
    }

    @Test func eventMetaIsItsCalendarName() {
        let i = hover(meeting(from: wed(14), to: wed(15)))
        #expect(i?.meta == "Gmail Work")
        #expect(i?.actions == [.startAsActivity, .edit, .openInCalendar])
    }

    @Test func repeatingEventIsReadOnlyAndHasNoEdit() {
        var e = meeting(from: wed(14), to: wed(15))
        e.isRepeating = true
        #expect(hover(e)?.actions == [.startAsActivity, .openInCalendar])
    }

    @Test func eventInACalendarSathiCannotWriteHasNoEdit() {
        let e = meeting(from: wed(14), to: wed(15), calendar: "gone")
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([e], read: ["gone"])
        let block = CalendarBlock(
            id: "x", title: e.title, interval: DateInterval(start: e.start, end: e.end), style: .event(colorHex: 0),
            source: .event(e), isAllDay: false, activityIDs: []
        )
        let i = h.engine.calendarHoverInfo(CalendarPlacedBlock(block: block, lane: 0, lanes: 1))
        #expect(i.actions == [.startAsActivity, .openInCalendar])
        #expect(i.meta == nil)
    }

    @Test func openRemindersOpensTheRemindersApp() {
        let h = EngineHarness(at: wed(10))
        h.engine.openReminders()
        #expect(h.links.opened == [URL(fileURLWithPath: "/System/Applications/Reminders.app")])
    }

    @Test func hoverDelaysAreOneShotWaitsFromTheSpec() {
        #expect(Timing.calendarHoverOpenDelay == 0.35)
        #expect(Timing.calendarHoverCloseDelay == 0.2)
    }
}
