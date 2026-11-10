import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Tracker calendar event rules")
struct EventRulesTests {
    private let hours = TrackerHours(prefs: TrackerPrefs(), calendar: .current)

    @Test func usableKeepsTimedEventsInsideTrackerHoursSortedByStart() {
        let events = [
            meeting("b", from: wed(11), to: wed(11, 30)),
            meeting("a", from: wed(10), to: wed(10, 30)),
            meeting("early", from: wed(8), to: wed(9, 30)),
            meeting("zero", from: wed(12), to: wed(12))
        ]
        let ids = EventRules.usable(events, hours: hours, written: [], items: []).map(\.id)
        #expect(ids == ["a", "b"])
    }

    @Test func theKeyTellsRecurringStartsApart() {
        let a = meeting("r", from: wed(10), to: wed(10, 30))
        let b = meeting("r", from: wed(14), to: wed(14, 30))
        #expect(EventRules.key(a) != EventRules.key(b))
    }

    @Test func firstStaysDropsAnEventThatStartsInsideTheKeptOne() {
        let kept = EventRules.firstStays([
            meeting("b", from: wed(10, 15), to: wed(10, 45)),
            meeting("a", from: wed(10), to: wed(10, 30)),
            meeting("c", from: wed(10, 30), to: wed(11))
        ])
        #expect(kept.map(\.id) == ["a", "c"])
    }

    @Test func spanCutRemovesThePartsAndKeepsTheRest() {
        let span = DateInterval(start: wed(10), end: wed(12))
        let parts = SpanCut.cut(span, removing: [
            DateInterval(start: wed(10, 30), end: wed(11)),
            DateInterval(start: wed(11, 30), end: wed(13))
        ])
        #expect(parts == [DateInterval(start: wed(10), end: wed(10, 30)), DateInterval(start: wed(11), end: wed(11, 30))])
    }

    @Test func aCalendarNameMatchingACategoryIsNotAddedAgain() {
        var prefs = TrackerPrefs()
        prefs.categories.append(ActivityCategory(name: "Gmail Work", colorHex: 0x111111))
        let cal = CalendarChoice(id: "work", title: "gmail work", account: "Gmail", colorHex: 0x4285F4)
        let pick = EventCategoryRule.pick(for: meeting(from: wed(10), to: wed(11)), prefs: prefs, calendars: [cal])
        #expect(pick == EventCategoryPick(name: "Gmail Work", added: nil))
    }

    @Test func anUnknownCalendarGivesNoCategory() {
        let pick = EventCategoryRule.pick(for: meeting(from: wed(10), to: wed(11)), prefs: TrackerPrefs(), calendars: [])
        #expect(pick.name == nil)
        #expect(pick.added == nil)
    }

    @Test func theAskFirstPromptShowsTheEventAndItsCategory() {
        let h = EngineHarness.tracker(at: wed(10))
        h.useEvents([meeting(from: wed(10, 30), to: wed(11))], mode: .askFirst)
        h.advance(minutes: 30)
        guard var s = h.engine.trackerPromptState(.eventAsk) else { return #expect(Bool(false)) }
        h.engine.fillEventAsk(&s)
        #expect(s.event?.id == "m1")
        #expect(s.draft.category == "Gmail Work")
        h.engine.setEventCategory("Meeting")
        h.engine.fillEventAsk(&s)
        #expect(s.draft.category == "Meeting")
    }
}
