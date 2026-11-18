import Foundation
import SathiCore
import SathiTestSupport
import Testing

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

    @Test(arguments: [(-5.0, "now"), (0.0, "now"), (30.0, "<1m"), (90.0, "1m"), (3600.0, "1h 0m"), (5430.0, "1h 30m")])
    func short(_ value: TimeInterval, _ expected: String) {
        #expect(Fmt.short(value) == expected)
    }

    @Test(arguments: [(0.0, "0:00"), (0.2, "0:01"), (59.0, "0:59"), (900.0, "15:00"), (-3.0, "0:00")])
    func clock(_ value: TimeInterval, _ expected: String) {
        #expect(Fmt.clock(value) == expected)
    }

    @Test(arguments: [(15, "15 min"), (60, "1 hour"), (120, "2 hours"), (90, "1 h 30 min"), (135, "2 h 15 min")])
    func interval(_ minutes: Int, _ expected: String) {
        #expect(Fmt.interval(minutes: minutes) == expected)
    }

    @Test(arguments: [(0.1, 0.0), (0.13, 0.25), (1.3, 1.25), (1.4, 1.5)])
    func roundToGlassStep(_ value: Double, _ expected: Double) {
        #expect(Fmt.roundToGlassStep(value) == expected)
    }

    @Test(arguments: [
        ((17, 0), (18, 30), "5:00 – 6:30 PM"),
        ((9, 5), (9, 13), "9:05 – 9:13 AM"),
        ((11, 30), (12, 30), "11:30 AM – 12:30 PM"),
        ((23, 30), (24, 30), "11:30 PM – 12:30 AM"),
        ((12, 0), (13, 0), "12:00 – 1:00 PM")
    ])
    func shortRange(_ from: (Int, Int), _ to: (Int, Int), _ expected: String) {
        let z = FixedZone.berlin
        let start = z.date(2026, 11, 12, from.0, from.1)
        let end = z.date(2026, 11, 12, 0).addingTimeInterval(TimeInterval((to.0 * 60 + to.1) * 60))
        #expect(Fmt.shortRange(start, end, calendar: z.calendar) == expected)
    }
}
