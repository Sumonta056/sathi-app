import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Water thanks copy")
struct WaterThanksCopyTests {
    private let zone = FixedZone.berlin

    private var now: Date { zone.date(2026, 3, 4, 10) }

    private func seeYou(after seconds: TimeInterval) -> String {
        Copywriter.seeYou(next: now.addingTimeInterval(seconds), now: now, calendar: zone.calendar)
    }

    @Test(arguments: [1.0, 2.0])
    func aFullGlassIsRefreshing(_ amount: Double) {
        #expect(Copywriter.celebrationTitle(.water, amount: amount) == "Ahh, refreshing!")
    }

    @Test(arguments: [0.25, 0.5])
    func aSipStillCounts(_ amount: Double) {
        #expect(Copywriter.celebrationTitle(.water, amount: amount) == "Every sip counts!")
    }

    @Test(arguments: [HabitID.reading, .meditation])
    func otherHabitsKeepTheirTitles(_ id: HabitID) {
        #expect(!Copywriter.celebrationTitle(id).isEmpty)
        #expect(!Copywriter.celebrationTitle(id, amount: 15).isEmpty)
    }

    private static let laterToday: [(TimeInterval, String)] = [
        (1800, "See you in 30 min"),
        (3600, "See you in 1 hour"),
        (5400, "See you in 1 h 30 min"),
        (1750, "See you in 30 min")
    ]

    @Test(arguments: laterToday)
    func seeYouLaterToday(_ seconds: TimeInterval, _ expected: String) {
        #expect(seeYou(after: seconds) == expected)
    }

    @Test(arguments: [0.0, -60.0])
    func seeYouSoonWhenAlreadyDue(_ seconds: TimeInterval) {
        #expect(seeYou(after: seconds) == "See you soon")
    }

    @Test func seeYouTomorrowWhenNextIsAnotherDay() {
        let next = zone.date(2026, 3, 5, 9, 30)
        #expect(Copywriter.seeYou(next: next, now: now, calendar: zone.calendar) == "See you tomorrow")
    }

    @Test func seeYouTomorrowAfterMidnightEvenWhenClose() {
        let late = zone.date(2026, 3, 4, 23, 50)
        let next = zone.date(2026, 3, 5, 0, 10)
        #expect(Copywriter.seeYou(next: next, now: late, calendar: zone.calendar) == "See you tomorrow")
    }

    @Test func seeYouTomorrowWhenNothingIsDue() {
        #expect(Copywriter.seeYou(next: .distantFuture, now: now, calendar: zone.calendar) == "See you tomorrow")
    }
}
