import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine builds the calendar hover card info")
struct EngineCalendarHoverTests {
    private func laid(_ b: CalendarBlock) -> CalendarLaidBlock {
        CalendarHoverInfoTests.laid(b)
    }

    private func hover(_ e: CalendarEventInfo, at now: Date? = nil, among: [CalendarLaidBlock] = []) -> CalendarHoverInfo? {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([e])
        guard let block = h.pageDay.blocks.first(where: { $0.title == e.title }) else { return nil }
        h.clock.now = now ?? e.start
        return h.engine.calendarHoverInfo(laid(block), among: among)
    }

    @Test func eventMetaIsItsCalendarName() {
        let i = hover(meeting(from: wed(14), to: wed(15)))
        #expect(i?.kindLabel == "Calendar event · Plan")
        #expect(i?.meta == "Gmail Work")
        #expect(i?.actions == [.startAsActivity, .edit, .openInCalendar])
    }

    @Test func startAsActivityShowsFiveMinutesBeforeTheStartButNotSix() {
        let e = meeting(from: wed(14), to: wed(15))
        #expect(hover(e, at: wed(13, 55))?.actions.first == .startAsActivity)
        #expect(hover(e, at: wed(13, 54))?.actions == [.edit, .openInCalendar])
    }

    @Test func startAsActivityIsHiddenWhenTheTrackerIsOff() {
        let e = meeting(from: wed(14), to: wed(15))
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([e])
        let block = h.pageDay.blocks.first { $0.title == e.title }
        h.engine.data.prefs.tracker.isOn = false
        h.clock.now = e.start
        #expect(block.map { h.engine.calendarHoverInfo(laid($0), among: []).actions } == [.edit, .openInCalendar])
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
        h.clock.now = e.start
        let i = h.engine.calendarHoverInfo(laid(block), among: [])
        #expect(i.actions == [.startAsActivity, .openInCalendar])
        #expect(i.meta == nil)
    }

    @Test func eventListsTheDoneDuringActivitiesItIsGiven() {
        let e = meeting(from: wed(14), to: wed(15))
        let a = Activity(text: "Notes", start: wed(14, 5), end: wed(14, 50))
        var done = laid(CalendarBlock(
            id: "n", title: "Notes", interval: a.interval, style: .activity(category: nil),
            source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
        ))
        done.doneDuring = EventRules.key(e)
        let i = hover(e, among: [done])
        #expect(i?.doneDuring.map(\.title) == ["Notes"])
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
