import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("CalendarPageStats")
struct CalendarPageStatsTests {
    let zone = FixedZone.berlin

    var wedDay: DateInterval { DateInterval(start: zone.date(2026, 3, 4, 6), end: zone.date(2026, 3, 5, 6)) }

    func event(_ id: String, _ from: Date, _ to: Date, allDay: Bool = false) -> CalendarEventInfo {
        CalendarEventInfo(id: id, title: id, start: from, end: to, calendarID: "work", isAllDay: allDay)
    }

    func row(_ kind: ActivityKind, _ category: String?, _ from: Date, _ to: Date) -> Activity {
        Activity(kind: kind, text: "x", category: category, start: from, end: to)
    }

    @Test func overlappingEventsCountOnce() {
        let events = [
            event("a", zone.date(2026, 3, 4, 10), zone.date(2026, 3, 4, 11)),
            event("b", zone.date(2026, 3, 4, 10, 30), zone.date(2026, 3, 4, 11, 30))
        ]
        let stats = CalendarPageStats.make(events: events, activities: [], interval: wedDay)
        #expect(stats.planned == 90 * 60)
    }

    @Test func allDayEventIsExcluded() {
        let events = [
            event("d", zone.date(2026, 3, 4), zone.date(2026, 3, 5), allDay: true),
            event("a", zone.date(2026, 3, 4, 10), zone.date(2026, 3, 4, 11))
        ]
        let stats = CalendarPageStats.make(events: events, activities: [], interval: wedDay)
        #expect(stats.planned == 60 * 60)
    }

    @Test func declinedEventIsNotPlanned() {
        var declined = event("x", zone.date(2026, 3, 4, 12), zone.date(2026, 3, 4, 13))
        declined.declined = true
        let events = [declined, event("a", zone.date(2026, 3, 4, 10), zone.date(2026, 3, 4, 11))]
        let stats = CalendarPageStats.make(events: events, activities: [], interval: wedDay)
        #expect(stats.planned == 60 * 60)
    }

    @Test func trackedLeavesOutAway() {
        let rows = [
            row(.work, "Focus", zone.date(2026, 3, 4, 10), zone.date(2026, 3, 4, 10, 45)),
            row(.away, nil, zone.date(2026, 3, 4, 10, 45), zone.date(2026, 3, 4, 11)),
            row(.buddy, "Health", zone.date(2026, 3, 4, 11), zone.date(2026, 3, 4, 11, 10))
        ]
        let stats = CalendarPageStats.make(events: [], activities: rows, interval: wedDay)
        #expect(stats.tracked == 55 * 60)
    }

    @Test func awayIsCountedApart() {
        let rows = [
            row(.work, "Focus", zone.date(2026, 3, 4, 10), zone.date(2026, 3, 4, 10, 45)),
            row(.away, nil, zone.date(2026, 3, 4, 10, 45), zone.date(2026, 3, 4, 11)),
            row(.away, nil, zone.date(2026, 3, 5, 5, 50), zone.date(2026, 3, 5, 6, 30))
        ]
        let stats = CalendarPageStats.make(events: [], activities: rows, interval: wedDay)
        #expect(stats.away == 25 * 60)
        #expect(stats.tracked == 45 * 60)
    }

    @Test func rowAcrossTheEndCountsOnlyInside() {
        let rows = [row(.work, nil, zone.date(2026, 3, 5, 5, 30), zone.date(2026, 3, 5, 6, 30))]
        let stats = CalendarPageStats.make(events: [], activities: rows, interval: wedDay)
        #expect(stats.tracked == 30 * 60)
    }

    @Test func rowAcrossTheStartCountsOnlyInside() {
        let rows = [row(.work, nil, zone.date(2026, 3, 4, 5), zone.date(2026, 3, 4, 7))]
        let stats = CalendarPageStats.make(events: [], activities: rows, interval: wedDay)
        #expect(stats.tracked == 60 * 60)
    }

    @Test func byCategoryIsLongestFirst() {
        let rows = [
            row(.work, "Mail", zone.date(2026, 3, 4, 9), zone.date(2026, 3, 4, 9, 10)),
            row(.work, "Focus", zone.date(2026, 3, 4, 10), zone.date(2026, 3, 4, 11)),
            row(.work, nil, zone.date(2026, 3, 4, 12), zone.date(2026, 3, 4, 12, 30)),
            row(.work, "Mail", zone.date(2026, 3, 4, 13), zone.date(2026, 3, 4, 13, 10)),
            row(.away, nil, zone.date(2026, 3, 4, 14), zone.date(2026, 3, 4, 16))
        ]
        let stats = CalendarPageStats.make(events: [], activities: rows, interval: wedDay)
        #expect(stats.byCategory == [
            CalendarCategoryTime(name: "Focus", seconds: 60 * 60),
            CalendarCategoryTime(name: nil, seconds: 30 * 60),
            CalendarCategoryTime(name: "Mail", seconds: 20 * 60)
        ])
    }
}
