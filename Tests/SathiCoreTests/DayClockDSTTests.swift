import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("DayClock DST")
struct DayClockDSTTests {
    private static let ny: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    private static func local(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        ny.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func wallClock(_ date: Date) -> [Int] {
        let c = Self.ny.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return [c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0]
    }

    @Test(arguments: [
        (3, 8, 480), (3, 8, 1290), (3, 8, 1320),
        (11, 1, 480), (11, 1, 1290), (11, 1, 1320)
    ])
    func atIsWallClockTimeOnADSTDay(_ month: Int, _ dayOfMonth: Int, _ minutes: Int) {
        let clock = DayClock(calendar: Self.ny)
        let result = clock.at(minutes, on: Self.local(2026, month, dayOfMonth, 12))
        #expect(wallClock(result) == [2026, month, dayOfMonth, minutes / 60, minutes % 60])
    }

    @Test(arguments: [(3, 8), (11, 1)])
    func meditationHoursAreWallClockTimesOnADSTDay(_ month: Int, _ dayOfMonth: Int) throws {
        var prefs = Prefs()
        prefs.meditation.startMinutes = 8 * 60
        prefs.meditation.endMinutes = 21 * 60 + 30
        let rules = MeditationRules(prefs: prefs, calendar: Self.ny)
        let start = rules.nextDue(now: Self.local(2026, month, dayOfMonth, 7), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(wallClock(start) == [2026, month, dayOfMonth, 8, 0])
        let done = try #require(Self.ny.date(byAdding: .day, value: -1, to: Self.local(2026, month, dayOfMonth, 21)))
        let next = rules.nextDue(now: done, lastDone: done, doneToday: 2, skipToday: false)
        #expect(wallClock(next) == [2026, month, dayOfMonth, 8, 0])
        #expect(rules.isActiveTime(Self.local(2026, month, dayOfMonth, 21, 29)))
        #expect(!rules.isActiveTime(Self.local(2026, month, dayOfMonth, 21, 30)))
    }

    @Test(arguments: [(3, 8), (11, 1)])
    func readingTimeIsWallClockTimeOnADSTDay(_ month: Int, _ dayOfMonth: Int) {
        let rules = ReadingRules(prefs: Prefs(), calendar: Self.ny)
        let due = rules.nextDue(now: Self.local(2026, month, dayOfMonth, 10), lastDone: nil, doneToday: 0, skipToday: false)
        #expect(wallClock(due) == [2026, month, dayOfMonth, 22, 0])
    }
}
