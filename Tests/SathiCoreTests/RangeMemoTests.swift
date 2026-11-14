import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Range memo")
struct RangeMemoTests {
    private final class Counter {
        var builds = 0
    }

    private func breathing() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 10, 0).addingTimeInterval(10)) {
            $0.prefs.water.enabled = false
            $0.prefs.reading.enabled = false
            $0.prefs.gym.enabled = false
            $0.prefs.meditation.sessionMinutes = 5
            $0.prefs.tracker.isOn = true
        }
        h.engine.startActivity(ActivityDraft(text: "Code review", length: .minutes(30)))
        h.engine.startMeditation()
        return h
    }

    private func week(_ h: EngineHarness, back: Int = 0) -> StatsRange {
        let now = h.clock.now.addingTimeInterval(-Double(back) * 7 * 86400)
        return StatsRange.containing(now, kind: .week, calendar: h.engine.calendar)
    }

    private func read(_ memo: RangeMemo<StatsRange, ReportsOverview>, _ h: EngineHarness, _ range: StatsRange, _ c: Counter) -> ReportsOverview {
        memo.value(range, range: range, engine: h.engine) { e, r in
            c.builds += 1
            return e.reportsOverview(r)
        }
    }

    private func tick(_ h: EngineHarness, seconds: Int) {
        for _ in 0 ..< seconds {
            h.clock.now = h.clock.now.addingTimeInterval(1)
            h.engine.tick()
        }
    }

    @Test func sessionTicksInsideAMinuteDoNotRebuild() {
        let h = breathing()
        let memo = RangeMemo<StatsRange, ReportsOverview>()
        let c = Counter()
        let range = week(h)
        _ = read(memo, h, range, c)
        for _ in 0 ..< 10 {
            tick(h, seconds: 1)
            _ = read(memo, h, range, c)
        }
        #expect(c.builds == 1)
    }

    @Test func aPastRangeDoesNotRebuildAcrossMinutes() {
        let h = breathing()
        let memo = RangeMemo<StatsRange, ReportsOverview>()
        let c = Counter()
        let range = week(h, back: 8)
        _ = read(memo, h, range, c)
        tick(h, seconds: 120)
        _ = read(memo, h, range, c)
        #expect(c.builds == 1)
    }

    @Test func aPastRangeRebuildsOnceTheDayChanges() {
        let h = breathing()
        let memo = RangeMemo<StatsRange, ReportsOverview>()
        let c = Counter()
        let range = week(h, back: 8)
        _ = read(memo, h, range, c)
        h.clock.now = h.clock.now.addingTimeInterval(86400)
        _ = read(memo, h, range, c)
        #expect(c.builds == 2)
    }

    @Test func theCurrentRangeRebuildsOnceAMinute() {
        let h = breathing()
        let memo = RangeMemo<StatsRange, ReportsOverview>()
        let c = Counter()
        let range = week(h)
        _ = read(memo, h, range, c)
        tick(h, seconds: 60)
        _ = read(memo, h, range, c)
        #expect(c.builds == 2)
    }

    @Test func changingTheRangeRebuilds() {
        let h = breathing()
        let memo = RangeMemo<StatsRange, ReportsOverview>()
        let c = Counter()
        _ = read(memo, h, week(h), c)
        _ = read(memo, h, week(h, back: 1), c)
        _ = read(memo, h, week(h, back: 1), c)
        #expect(c.builds == 2)
    }

    @Test func realDataChangesRebuild() {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        let memo = RangeMemo<StatsRange, ReportsOverview>()
        let c = Counter()
        let range = week(h, back: 1)
        _ = read(memo, h, range, c)
        let start = range.interval.start.addingTimeInterval(36000)
        _ = h.engine.addPastActivity(ActivityEdit(text: "Old", category: nil, start: start, end: start.addingTimeInterval(1800)))
        _ = read(memo, h, range, c)
        h.engine.data.prefs.water.enabled.toggle()
        _ = read(memo, h, range, c)
        #expect(c.builds == 3)
    }

    @Test func calendarPageMemoUsesTheRangeEnd() {
        let h = breathing()
        let memo = RangeMemo<CalendarPageRange, Int>()
        let c = Counter()
        let current = CalendarPageRange.containing(h.clock.now, kind: .week, calendar: h.engine.calendar)
        let past = current.previous.previous
        let read = { (r: CalendarPageRange) in
            _ = memo.value(r, end: r.interval.end, engine: h.engine) { _, _ in
                c.builds += 1
                return 0
            }
        }
        read(past)
        tick(h, seconds: 120)
        read(past)
        #expect(c.builds == 1)
        read(current)
        tick(h, seconds: 60)
        read(current)
        #expect(c.builds == 3)
    }

    @Test func activitiesPageBuildsTheDaysOnce() {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        h.engine.startActivity(ActivityDraft(text: "Spec", length: .minutes(30)))
        h.advance(minutes: 40)
        let range = week(h)
        let page = h.engine.activitiesPage(range)
        #expect(page.days == h.engine.activityDays(in: range))
        #expect(page.stats == h.engine.activityRange(range))
        #expect(page.day == nil)
        let today = StatsRange.containing(h.clock.now, kind: .day, calendar: h.engine.calendar)
        #expect(h.engine.activitiesPage(today).day == h.engine.activityDay(DayKey(h.clock.now, calendar: h.engine.calendar)))
    }
}
