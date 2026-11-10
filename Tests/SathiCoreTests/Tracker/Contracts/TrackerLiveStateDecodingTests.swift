import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Tracker live state decoding")
struct TrackerLiveStateDecodingTests {
    private func live(_ json: String) throws -> LiveState {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(LiveState.self, from: Data(json.utf8))
    }

    private func roundTrip(_ l: LiveState) throws -> LiveState {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(LiveState.self, from: e.encode(l))
    }

    @Test func oldStateWithoutTheKeyLoadsAnEmptyTracker() throws {
        let l = try live(#"{"bottleLevel":0.5}"#)
        #expect(l.tracker == TrackerLiveState())
        #expect(l.tracker.running == nil)
        #expect(l.tracker.prompt == nil)
        #expect(l.bottleLevel == 0.5)
    }

    @Test func aBadTrackerValueKeepsTheRest() throws {
        let l = try live(#"{"tracker":42,"bottleLevel":0.5}"#)
        #expect(l.tracker == TrackerLiveState())
        #expect(l.bottleLevel == 0.5)
    }

    @Test func aBadRunningActivityIsDroppedAndTheRestStays() throws {
        let l = try live(#"{"tracker":{"running":{"text":"no id"},"lastEndOfDay":"2026-11-09"}}"#)
        #expect(l.tracker.running == nil)
        #expect(l.tracker.lastEndOfDay?.raw == "2026-11-09")
    }

    @Test func oldTrackerStateWithoutAwayDetailsLoadsEmptyDetails() throws {
        let l = try live(#"{"tracker":{"lastEndOfDay":"2026-11-09"}}"#)
        #expect(l.tracker.away == TrackerAwayDetails())
        #expect(l.tracker.prompt?.doneAt == nil)
    }

    @Test func badAwayDetailsKeepTheRest() throws {
        let l = try live(#"{"tracker":{"away":{"awayItems":[42],"lastAway":7},"lastEndOfDay":"2026-11-09"}}"#)
        #expect(l.tracker.away.awayItems.isEmpty)
        #expect(l.tracker.away.lastAway == nil)
        #expect(l.tracker.lastEndOfDay?.raw == "2026-11-09")
    }

    @Test func awayDetailsAndTheDoneTimeRoundTrip() throws {
        let start = day(2026, 11, 9, 9)
        var l = LiveState()
        l.tracker.prompt = PromptState(kind: .whatNow, shownAt: start, askTime: start, switchFrom: start, doneAt: start)
        l.tracker.away.lastAway = AwaySpan(start: start, end: start.addingTimeInterval(600), cause: .idle, place: .lunch)
        l.tracker.away.awayItems = [ActivityID()]
        l.tracker.away.loggedWhileAway = [Activity(kind: .event, text: "Standup", start: start, end: start.addingTimeInterval(600))]
        l.tracker.away.endedByAway = RunningActivity(text: "Spec", start: start, expectedLength: .minutes(30), askAt: start)
        #expect(try roundTrip(l).tracker == l.tracker)
    }

    @Test func anUnknownPromptKindIsDropped() throws {
        let l = try live(#"{"tracker":{"prompt":{"kind":"zzz","shownAt":"2026-11-09T09:00:00Z","askTime":"2026-11-09T09:00:00Z"}}}"#)
        #expect(l.tracker.prompt == nil)
    }

    @Test func fullStateRoundTripsWithWholeSeconds() throws {
        let start = day(2026, 11, 9, 9).addingTimeInterval(0.4)
        var running = RunningActivity(text: "Client work", category: "Coding", start: start, expectedLength: .minutes(60), askAt: start)
        running.calendarID = "work"
        running.quietUntil = start.addingTimeInterval(3600.7)
        var l = LiveState()
        l.tracker.running = running
        l.tracker.prompt = PromptState(kind: .stillOnIt, shownAt: start, askTime: start)
        l.tracker.awaySince = start
        l.tracker.awayCause = .idle
        l.tracker.lastInput = start
        l.tracker.lastEndOfDay = DayKey(start, calendar: .current)
        l.tracker.lastActivity = ActivityDraft(text: "Standup", category: "Meeting")
        let back = try roundTrip(l)
        var expected = l.tracker
        expected.running?.quietUntil = start.addingTimeInterval(3600.7).wholeSecond
        expected.awaySince = start.wholeSecond
        expected.lastInput = start.wholeSecond
        #expect(back.tracker == expected)
        #expect(back.tracker.running?.start == start.wholeSecond)
        #expect(back.tracker.running?.quietUntil == start.addingTimeInterval(3600.7).wholeSecond)
        #expect(back.tracker.prompt?.shownAt == start.wholeSecond)
    }

    @Test func aNewRunningActivityIsConfirmedUntilItsFirstAsk() {
        let start = day(2026, 11, 9, 9)
        let ask = start.addingTimeInterval(1800)
        let r = RunningActivity(text: "Plan", start: start, expectedLength: .minutes(30), askAt: ask)
        #expect(r.kind == .work)
        #expect(r.lastAnswer == start)
        #expect(r.confirmedUntil == ask)
    }

    @Test func aRunningActivityBecomesAnActivityWithTheSameFields() {
        let start = day(2026, 11, 9, 9)
        var r = RunningActivity(text: "Plan", category: "Coding", start: start, expectedLength: .open, askAt: start)
        r.calendarID = "work"
        let end = start.addingTimeInterval(1800.6)
        let a = r.activity(until: end)
        #expect(a.id == r.id)
        #expect(a.kind == .work)
        #expect(a.text == "Plan")
        #expect(a.category == "Coding")
        #expect(a.start == start)
        #expect(a.end == end.wholeSecond)
        #expect(a.calendarID == "work")
        #expect(a.eventID == nil)
    }
}
