import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Coming up list")
struct ComingUpListTests {
    private let calendar = Calendar.current
    private var now: Date { day(2026, 3, 4, 10) }

    private func item(_ title: String, _ time: Date) -> ComingUpItem {
        ComingUpItem(kind: .daySummary, title: title, time: time)
    }

    @Test func itemsComeInTimeOrder() {
        let list = ComingUpList.make(
            items: [item("c", day(2026, 3, 4, 14)), item("a", day(2026, 3, 4, 11)), item("b", day(2026, 3, 4, 12))],
            now: now, calendar: calendar
        )
        #expect(list.map(\.title) == ["a", "b", "c"])
    }

    @Test func itemsAfterTodayAreLeftOut() {
        let list = ComingUpList.make(
            items: [item("tomorrow", day(2026, 3, 5, 9)), item("late", day(2026, 3, 4, 23, 59))],
            now: now, calendar: calendar
        )
        #expect(list.map(\.title) == ["late"])
    }

    @Test func itemsBeforeOrAtNowAreLeftOut() {
        let list = ComingUpList.make(
            items: [item("past", day(2026, 3, 4, 9)), item("at", now), item("next", day(2026, 3, 4, 10, 1))],
            now: now, calendar: calendar
        )
        #expect(list.map(\.title) == ["next"])
    }

    @Test func atMostSixItemsStayAndTheEarliestWin() {
        let items = (1 ... 9).map { item("i\($0)", day(2026, 3, 4, 10, $0)) }.reversed()
        let list = ComingUpList.make(items: Array(items), now: now, calendar: calendar)
        #expect(list.count == Limits.comingUpMax)
        #expect(list.map(\.title) == ["i1", "i2", "i3", "i4", "i5", "i6"])
    }

    @Test func emptyInputGivesEmptyList() {
        #expect(ComingUpList.make(items: [], now: now, calendar: calendar).isEmpty)
    }
}
