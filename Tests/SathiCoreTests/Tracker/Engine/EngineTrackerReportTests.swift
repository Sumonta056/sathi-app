import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker report API")
struct EngineTrackerReportTests {
    private let items = [
        Activity(text: "Spec", category: "Coding", start: wed(9), end: wed(10)),
        Activity(text: "Review", category: "Review", start: wed(10), end: wed(10, 30)),
        Activity(text: "Mail", category: "Email", start: day(2026, 3, 2, 9), end: day(2026, 3, 2, 9, 20))
    ]

    private func harness() -> EngineHarness {
        EngineHarness.tracker(at: wed(11), activities: items)
    }

    @Test func aDayHasItsItemsInOrderAndItsTrackerHours() {
        let h = harness()
        let d = h.engine.activityDay(DayKey(wed(11), calendar: .current))
        #expect(d.activities.map(\.text) == ["Spec", "Review"])
        #expect(d.hours == DateInterval(start: wed(9), end: wed(18)))
        #expect(d.running == nil)
    }

    @Test func todayShowsTheRunningActivityUpToNow() {
        let h = harness()
        h.start("Now")
        h.clock.advance(minutes: 10)
        let d = h.engine.activityDay(DayKey(wed(11), calendar: .current))
        #expect(d.running?.text == "Now")
        #expect(d.running?.end == wed(11, 10))
    }

    @Test func aMonthListsOnlyDaysWithActivities() {
        let h = harness()
        let month = MonthKey(wed(11), calendar: .current)
        #expect(h.engine.daysWithActivities(in: month) == [DayKey(day(2026, 3, 2), calendar: .current), DayKey(wed(11), calendar: .current)])
        #expect(h.engine.activityDays(in: month).map(\.activities.count) == [1, 2])
    }

    @Test func anEditSavesNewTextAndTimes() {
        let h = harness()
        let id = items[1].id
        let r = h.engine.editActivity(id, ActivityEdit(text: " Code review ", category: "Review", start: wed(10), end: wed(10, 45)))
        #expect(r == .saved(id))
        #expect(h.saved.first { $0.id == id }?.text == "Code review")
        #expect(h.saved.first { $0.id == id }?.end == wed(10, 45))
    }

    @Test func anEditThatOverlapsIsRefused() {
        let h = harness()
        let r = h.engine.editActivity(items[1].id, ActivityEdit(text: "Review", category: nil, start: wed(9, 50), end: wed(10, 30)))
        #expect(r == .overlap)
        #expect(h.saved.first { $0.id == items[1].id }?.start == wed(10))
    }

    @Test func anEditOfAMissingItemIsNotFound() {
        let h = harness()
        #expect(h.engine.editActivity(ActivityID(), ActivityEdit(text: "x", category: nil, start: wed(12), end: wed(13))) == .notFound)
    }

    @Test func addPastFillsAGapAndRefusesAnOverlap() {
        let h = harness()
        #expect(h.engine.addPastActivity(ActivityEdit(text: "Standup", category: "Meeting", start: wed(8, 30), end: wed(8, 45))) != .overlap)
        #expect(h.saved.contains { $0.text == "Standup" })
        #expect(h.engine.addPastActivity(ActivityEdit(text: "X", category: nil, start: wed(9, 30), end: wed(9, 45))) == .overlap)
        #expect(h.engine.addPastActivity(ActivityEdit(text: "", category: nil, start: wed(7), end: wed(8))) == .emptyText)
    }

    @Test func addPastCannotOverlapTheRunningActivity() {
        let h = harness()
        h.start("Now")
        h.clock.advance(minutes: 20)
        #expect(h.engine.addPastActivity(ActivityEdit(text: "X", category: nil, start: wed(11, 5), end: wed(11, 15))) == .overlap)
    }

    @Test func deleteRemovesTheItem() {
        let h = harness()
        h.engine.deleteActivity(items[0].id)
        #expect(!h.saved.contains { $0.id == items[0].id })
    }

    @Test func recentsComeFromTheStoreNewestFirst() {
        let h = harness()
        #expect(h.engine.recentActivities.map(\.text) == ["Review", "Spec", "Mail"])
        #expect(h.engine.trackerPromptState(.whatNow)?.recents.count == 3)
    }

    @Test func aFreshDraftUsesTheDefaults() {
        let h = EngineHarness.tracker(at: wed(10)) {
            $0.prefs.tracker.calendarOnByDefault = true
            $0.prefs.tracker.defaultCalendarID = "work"
        }
        let d = h.engine.trackerPromptState(.whatNow)?.draft
        #expect(d?.category == "Coding")
        #expect(d?.length == .minutes(30))
        #expect(d?.askOffsetMinutes == 0)
        #expect(d?.calendarID == "work")
    }
}
