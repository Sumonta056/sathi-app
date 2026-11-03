import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("DayKey")
struct DayKeyTests {
    private let ny = FixedZone.newYork

    @Test func dayKeyRoundTripsAsAString() throws {
        let key = try #require(DayKey(raw: "2026-11-03"))
        let data = try JSONEncoder().encode([key])
        #expect(String(bytes: data, encoding: .utf8) == #"["2026-11-03"]"#)
        #expect(try JSONDecoder().decode([DayKey].self, from: data) == [key])
        #expect(key.raw == "2026-11-03")
    }

    @Test func dayKeyRejectsAnImpossibleDate() { #expect(DayKey(raw: "2026-02-30") == nil) }

    @Test(arguments: ["2026-13-40", "2026-1-3", "2026-11-3", "", "abcd-ef-gh", "2026-11-03T00:00", "26-11-03", " 2026-11-03"])
    func dayKeyRejectsABadFormat(_ raw: String) {
        #expect(DayKey(raw: raw) == nil)
    }

    @Test func dayKeyAcceptsALeapDay() {
        #expect(DayKey(raw: "2028-02-29")?.raw == "2028-02-29")
        #expect(DayKey(raw: "2026-02-29") == nil)
    }

    @Test func decodingABadStringThrows() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode([DayKey].self, from: Data(#"["2026-13-40"]"#.utf8))
        }
    }

    @Test(arguments: [(3, 8), (11, 1)])
    func dayKeyIsStableAcrossDST(_ month: Int, _ dayOfMonth: Int) {
        let expected = String(format: "2026-%02d-%02d", month, dayOfMonth)
        #expect(DayKey(ny.date(2026, month, dayOfMonth, 0, 30), calendar: ny.calendar).raw == expected)
        #expect(DayKey(ny.date(2026, month, dayOfMonth, 23, 30), calendar: ny.calendar).raw == expected)
    }

    @Test func dayKeyUsesTheCalendarTimeZone() {
        let instant = FixedZone.berlin.date(2026, 11, 3, 2)
        #expect(DayKey(instant, calendar: FixedZone.berlin.calendar).raw == "2026-11-03")
        #expect(DayKey(instant, calendar: ny.calendar).raw == "2026-11-02")
    }

    @Test func dayKeyIsGregorianWithABuddhistCalendar() {
        let buddhist = FixedZone("Europe/Berlin", calendar: .buddhist)
        #expect(DayKey(buddhist.date(2569, 11, 3, 12), calendar: buddhist.calendar).raw == "2026-11-03")
    }

    @Test(arguments: [(3, 8), (11, 1), (11, 3)])
    func startIsMidnightOfThatDay(_ month: Int, _ dayOfMonth: Int) throws {
        let key = try #require(DayKey(raw: String(format: "2026-%02d-%02d", month, dayOfMonth)))
        #expect(key.start(in: ny.calendar) == ny.date(2026, month, dayOfMonth))
        #expect(ny.wallClock(key.start(in: ny.calendar)) == [2026, month, dayOfMonth, 0, 0])
    }

    @Test func keysSortByDate() throws {
        let a = try #require(DayKey(raw: "2026-02-28"))
        let b = try #require(DayKey(raw: "2026-03-01"))
        let c = try #require(DayKey(raw: "2027-01-01"))
        #expect(a < b)
        #expect(b < c)
        #expect([c, a, b].sorted() == [a, b, c])
    }
}
