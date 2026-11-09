import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Month key")
struct MonthKeyTests {
    private let berlin = FixedZone.berlin

    @Test func keyOfADateUsesTheUsersTimeZone() {
        let lateNight = berlin.date(2026, 11, 30, 23, 30)
        #expect(MonthKey(lateNight, calendar: berlin.calendar).raw == "2026-11")
    }

    @Test func rawParsesAndRefusesBadText() {
        #expect(MonthKey(raw: "2026-02") == MonthKey(year: 2026, month: 2))
        #expect(MonthKey(raw: "2026-13") == nil)
        #expect(MonthKey(raw: "26-1") == nil)
        #expect(MonthKey(year: 2026, month: 0) == nil)
    }

    @Test func startAndEndCoverTheWholeMonth() throws {
        let key = try #require(MonthKey(year: 2026, month: 12))
        #expect(key.start(in: berlin.calendar) == berlin.date(2026, 12, 1))
        #expect(key.end(in: berlin.calendar) == berlin.date(2027, 1, 1))
    }

    @Test func nextAndPreviousCrossTheYear() throws {
        let dec = try #require(MonthKey(year: 2026, month: 12))
        let jan = try #require(MonthKey(year: 2027, month: 1))
        #expect(dec.next == jan)
        #expect(jan.previous == dec)
        #expect(dec < jan)
    }

    @Test func roundTripsAsText() throws {
        let key = try #require(MonthKey(year: 2026, month: 3))
        let data = try JSONEncoder().encode([key])
        #expect(String(bytes: data, encoding: .utf8) == #"["2026-03"]"#)
        #expect(try JSONDecoder().decode([MonthKey].self, from: data) == [key])
    }
}
