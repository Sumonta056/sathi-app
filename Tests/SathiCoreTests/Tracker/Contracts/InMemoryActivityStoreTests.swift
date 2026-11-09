import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("In-memory activity store")
struct InMemoryActivityStoreTests {
    private let utc = FixedZone("UTC")

    private func item(_ text: String, _ m: Int, _ d: Int) -> Activity {
        let start = utc.date(2026, m, d, 9)
        return Activity(text: text, start: start, end: start.addingTimeInterval(1800))
    }

    @Test func startsWithTheGivenActivitiesByMonth() throws {
        let store = InMemoryActivityStore(activities: [item("A", 10, 31), item("B", 11, 2)], calendar: utc.calendar)
        let nov = try #require(MonthKey(year: 2026, month: 11))
        #expect(store.month(nov).items.map(\.text) == ["B"])
        #expect(store.savedMonths().map(\.raw) == ["2026-10", "2026-11"])
    }

    @Test func aSavedMonthLoadsBack() throws {
        let store = InMemoryActivityStore()
        let key = try #require(MonthKey(year: 2026, month: 11))
        let month = ActivityMonth(key: key, items: [item("Plan", 11, 9)])
        store.save(month)
        #expect(store.month(key) == month)
        #expect(store.saves == 1)
    }

    @Test func anUnknownMonthIsEmpty() throws {
        let key = try #require(MonthKey(year: 2020, month: 1))
        #expect(InMemoryActivityStore().month(key) == ActivityMonth(key: key, items: []))
    }

    @Test func allActivitiesAreSortedByMonth() {
        let store = InMemoryActivityStore(activities: [item("B", 11, 2), item("A", 10, 31)], calendar: utc.calendar)
        #expect(store.allActivities().map(\.text) == ["A", "B"])
    }

    @Test func flushReportsFailure() {
        let store = InMemoryActivityStore()
        #expect(store.flush())
        store.failFlush = true
        #expect(!store.flush())
        #expect(store.flushes == 2)
    }
}
