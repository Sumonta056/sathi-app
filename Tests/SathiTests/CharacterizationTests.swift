import Foundation
import Testing
@testable import Sathi

private func day(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

@Suite("Fmt")
struct FmtTests {
    @Test(arguments: [(0.0, "0"), (0.25, "¼"), (0.5, "½"), (1.0, "1"), (1.5, "1½"), (2.75, "2¾"), (1.1, "1")])
    func count(_ value: Double, _ expected: String) {
        #expect(Fmt.count(value) == expected)
    }

    @Test func glassesPluralization() {
        #expect(Fmt.glasses(1) == "1 glass")
        #expect(Fmt.glasses(0.5) == "½ glass")
        #expect(Fmt.glasses(2) == "2 glasses")
    }

    @Test(arguments: [(-5.0, "now"), (0.0, "now"), (30.0, "<1m"), (90.0, "1m"), (3_600.0, "1h 0m"), (5_430.0, "1h 30m")])
    func short(_ value: TimeInterval, _ expected: String) {
        #expect(Fmt.short(value) == expected)
    }

    @Test(arguments: [(0.0, "0:00"), (0.2, "0:01"), (59.0, "0:59"), (900.0, "15:00"), (-3.0, "0:00")])
    func clock(_ value: TimeInterval, _ expected: String) {
        #expect(Fmt.clock(value) == expected)
    }
}

@Suite("Copywriter")
struct CopywriterTests {
    @Test func usesNameWhenGiven() {
        let titles = (0..<30).map { _ in Copywriter.pick(.water, .nudge, name: "Mridul").title }
        #expect(titles.contains { $0.contains("Mridul") })
        #expect(!titles.contains { $0.contains("friend") })
    }

    @Test func fallsBackToFriendForBlankName() {
        let titles = (0..<60).map { _ in Copywriter.pick(.reading, .nudge, name: "   ").title }
        #expect(titles.contains { $0.contains("friend") })
    }

    @Test(arguments: HabitID.allCases)
    func everyLevelHasCopy(_ id: HabitID) {
        for level in [Level.nudge, .persist] {
            let copy = Copywriter.pick(id, level, name: "A")
            #expect(!copy.title.isEmpty)
            #expect(!copy.body.isEmpty)
        }
    }
}

@Suite("Model")
struct ModelTests {
    @Test func scheduleKeyIgnoresNonScheduleFields() {
        var p = Prefs()
        let key = p.scheduleKey
        p.name = "Other"
        p.soundOn.toggle()
        p.snoozeMinutes = 9
        #expect(p.scheduleKey == key)
    }

    @Test func scheduleKeyTracksScheduleFields() {
        var p = Prefs()
        let key = p.scheduleKey
        p.waterIntervalMinutes = 60
        #expect(p.scheduleKey != key)
    }

    @Test func persistedRoundTrip() throws {
        var state = Persisted()
        state.drinks = [DrinkEntry(date: day(2026, 1, 2, 10), glasses: 1.5)]
        state.reads = [ReadEntry(date: day(2026, 1, 2, 22), minutes: 15)]
        state.bottleLevel = 0.4
        let decoded = try JSONDecoder().decode(Persisted.self, from: JSONEncoder().encode(state))
        #expect(decoded.prefs == state.prefs)
        #expect(decoded.drinks.count == 1)
        #expect(decoded.reads.first?.minutes == 15)
        #expect(decoded.bottleLevel == 0.4)
    }

    @Test func defaultPrefs() {
        let p = Prefs()
        #expect(p.waterIntervalMinutes == 120)
        #expect(p.waterStartMinutes == 570)
        #expect(p.waterEndMinutes == 1_110)
        #expect(p.readingTimeMinutes == 1_320)
        #expect(p.waterStrictness == .strict)
        #expect(p.readingStrictness == .persistent)
    }
}

@MainActor
@Suite("Engine schedule", .serialized)
struct EngineScheduleTests {
    private func engine() -> Engine {
        let e = Engine()
        var state = Persisted()
        state.prefs.soundOn = false
        e.data = state
        return e
    }

    @Test func nextWaterDueInsideHours() {
        let e = engine()
        #expect(e.nextWaterDue(after: day(2026, 3, 4, 10)) == day(2026, 3, 4, 12))
    }

    @Test func nextWaterDueBeforeStartSnapsToStart() {
        let e = engine()
        #expect(e.nextWaterDue(after: day(2026, 3, 4, 5)) == day(2026, 3, 4, 9, 30))
    }

    @Test func nextWaterDueAfterEndMovesToNextMorning() {
        let e = engine()
        #expect(e.nextWaterDue(after: day(2026, 3, 4, 17)) == day(2026, 3, 5, 9, 30))
    }

    @Test func inWaterHoursBoundaries() {
        let e = engine()
        #expect(!e.inWaterHours(day(2026, 3, 4, 9, 29)))
        #expect(e.inWaterHours(day(2026, 3, 4, 9, 30)))
        #expect(e.inWaterHours(day(2026, 3, 4, 18, 29)))
        #expect(!e.inWaterHours(day(2026, 3, 4, 18, 30)))
    }

    @Test func glassesSumsOnlyThatDay() {
        let e = engine()
        e.data.drinks = [
            DrinkEntry(date: day(2026, 3, 4, 10), glasses: 1),
            DrinkEntry(date: day(2026, 3, 4, 15), glasses: 0.5),
            DrinkEntry(date: day(2026, 3, 5, 10), glasses: 2),
        ]
        #expect(e.glasses(on: day(2026, 3, 4, 12)) == 1.5)
    }

    @Test func waterStreakCountsConsecutiveGoalDays() {
        let e = engine()
        let now = Date()
        e.now = now
        e.data.drinks = (0..<3).map { DrinkEntry(date: now.addingTimeInterval(TimeInterval(-$0 * 86_400)), glasses: 8) }
        #expect(e.streak(.water) == 3)
    }

    @Test func streakResetKeepsOnlyDaysAfterReset() {
        let e = engine()
        let now = Date()
        e.now = now
        e.data.drinks = (0..<3).map { DrinkEntry(date: now.addingTimeInterval(TimeInterval(-$0 * 86_400)), glasses: 8) }
        e.data.streakReset[HabitID.water.rawValue] = now.addingTimeInterval(-1)
        #expect(e.streak(.water) == 1)
    }

    @Test func logBottleConvertsLevelToGlasses() {
        let e = engine()
        e.data.bottleLevel = 1
        e.logBottle(newLevel: 0.5)
        #expect(e.data.bottleLevel == 0.5)
        #expect(e.data.drinks.last?.glasses == 1.5)
        e.ui.closeCelebrate()
    }

    @Test func logWaterRoundsToQuarterWithMinimum() {
        let e = engine()
        e.logWater(0.05)
        #expect(e.data.drinks.last?.glasses == 0.25)
        e.logWater(1.3)
        #expect(e.data.drinks.last?.glasses == 1.25)
        e.ui.closeCelebrate()
    }
}
