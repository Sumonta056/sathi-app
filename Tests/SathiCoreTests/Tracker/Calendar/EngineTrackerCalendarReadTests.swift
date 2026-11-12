import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker calendar read")
struct EngineTrackerCalendarReadTests {
    @Test func readingIsOffByDefaultAndNothingIsRead() {
        #expect(TrackerPrefs().readsEvents == false)
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.eventsValue = [meeting(from: wed(10, 30), to: wed(11))]
        h.engine.data.prefs.tracker.readCalendarIDs = ["work"]
        h.advance(minutes: 40)
        #expect(h.calendarWriter.eventReads.isEmpty)
        #expect(h.running == nil)
    }

    @Test func onlyTheTickedCalendarsAreReadAndEachReadIsOneDayAtMost() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([
            meeting("h1", "Dentist", from: wed(10, 30), to: wed(11), calendar: "home"),
            meeting("w1", "Standup", from: wed(10, 40), to: wed(11))
        ])
        h.advance(minutes: 30)
        #expect(h.running == nil)
        h.advance(minutes: 10)
        #expect(h.running?.text == "Standup")
        #expect(h.calendarWriter.eventReads.allSatisfy { $0.duration <= 24 * 3600 })
    }

    @Test func allDayDeclinedAndSathiWrittenEventsAreSkippedAndFreeEventsCount() {
        let mine = Activity(text: "Spec", start: wed(9), end: wed(9, 20), calendarID: "work", eventID: "sathi1")
        let block = Activity(kind: .timeBlock, text: "Deep work", start: wed(10, 10), end: wed(10, 15))
        let h = EngineHarness.tracker(at: wed(10), activities: [mine, block])
        h.useEvents([
            meeting("a", "Holiday", from: wed(0), to: wed(23, 59), allDay: true),
            meeting("d", "Declined", from: wed(10, 5), to: wed(10, 20), declined: true),
            meeting("sathi1", "Spec", from: wed(10, 8), to: wed(10, 28)),
            meeting("tb", "Deep work", from: wed(10, 10), to: wed(10, 40)),
            meeting("free", "Lunch talk", from: wed(10, 30), to: wed(11))
        ])
        for _ in 0 ..< 29 {
            h.advance(minutes: 1)
        }
        #expect(h.running == nil)
        #expect(h.notes.isEmpty)
        h.advance(minutes: 1)
        #expect(h.running?.text == "Lunch talk")
    }

    @Test func eventsOutsideTrackerHoursOrOnANonTrackerDayAreSkipped() {
        let h = EngineHarness.tracker(at: wed(17, 30))
        h.useEvents([meeting(from: wed(18, 10), to: wed(18, 40))])
        h.advance(minutes: 45)
        #expect(h.running == nil)
        #expect(h.notes.isEmpty)
    }

    @Test func theNextEventStartIsATickDeadline() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([meeting(from: wed(10, 12), to: wed(11))])
        #expect(h.engine.nextTickDelay() <= 12 * 60)
    }

    @Test func ticksWithNoDueTimeDoNotReadAgain() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([meeting(from: wed(13), to: wed(14))])
        let reads = h.calendarWriter.eventReads.count
        for _ in 0 ..< 5 {
            h.engine.tick()
        }
        #expect(h.calendarWriter.eventReads.count == reads)
    }

    @Test func anEventAddedLaterIsSeenAtTheNextAskTime() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([])
        h.start("Spec", minutes: 15)
        h.calendarWriter.eventsValue = [meeting(from: wed(10, 20), to: wed(10, 50))]
        h.advance(minutes: 15)
        h.engine.stillOnIt(minutes: 30)
        h.advance(minutes: 5)
        #expect(h.running?.text == "Standup")
    }

    @Test func categoryIsTheTitlePickThenTheCalendarCategoryThenTheCalendarName() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.data.prefs.tracker.categoryByCalendar = ["work": "Cefalo Meetings"]
        h.engine.data.prefs.tracker.eventCategoryByTitle = ["Retro": "Review"]
        h.useEvents([
            meeting("r", "Retro", from: wed(10, 10), to: wed(10, 20)),
            meeting("s", "Standup", from: wed(10, 20), to: wed(10, 30)),
            meeting("x", "Sync", from: wed(10, 30), to: wed(10, 40), calendar: "home")
        ], read: ["work", "home"])
        h.advance(minutes: 10)
        #expect(h.running?.category == "Review")
        h.advance(minutes: 10)
        #expect(h.running?.category == "Cefalo Meetings")
        h.advance(minutes: 10)
        #expect(h.running?.category == "Home")
        #expect(h.engine.activityCategories.last == ActivityCategory(name: "Home", colorHex: 0x34A853))
    }

    @Test func aDeletedCalendarCategoryFallsBackToTheCalendarName() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.data.prefs.tracker.categoryByCalendar = ["work": "Gone"]
        h.useEvents([meeting(from: wed(10, 10), to: wed(10, 40))])
        h.advance(minutes: 10)
        #expect(h.running?.category == "Gmail Work")
    }

    @Test func theReadableCalendarsAreAllCalendars() {
        let h = EngineHarness.tracker(at: wed(10))
        h.calendarWriter.readable = [CalendarChoice(id: "sub", title: "Team", account: "Gmail", colorHex: 0x123456)]
        #expect(h.engine.readableCalendarChoices().map(\.id) == ["sub"])
    }
}
