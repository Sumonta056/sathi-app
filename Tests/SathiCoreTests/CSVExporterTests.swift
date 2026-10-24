import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("CSVExporter")
struct CSVExporterTests {
    private let zone = FixedZone.berlin

    private func csv(_ events: [HistoryEvent], _ timeZone: TimeZone? = nil) -> String {
        CSVExporter.csv(events, timeZone: timeZone ?? zone.timeZone)
    }

    @Test func emptyInputGivesTheHeaderOnly() {
        #expect(csv([]) == "timestamp,habit,kind,amount\n")
    }

    @Test func oneLinePerEventEndingWithANewline() {
        let text = csv([.done(.water, 1, at: zone.date(2026, 3, 4, 10))])
        #expect(text == "timestamp,habit,kind,amount\n2026-03-04T10:00:00+01:00,water,done,1\n")
    }

    @Test func linesAreSortedByDate() {
        let events: [HistoryEvent] = [
            .done(.reading, 15, at: zone.date(2026, 3, 4, 22)),
            .snooze(.water, at: zone.date(2026, 3, 4, 11, 5)),
            .skip(.meditation, at: zone.date(2026, 3, 3, 8))
        ]
        #expect(csv(events) == """
        timestamp,habit,kind,amount
        2026-03-03T08:00:00+01:00,meditation,skip,0
        2026-03-04T11:05:00+01:00,water,snooze,0
        2026-03-04T22:00:00+01:00,reading,done,15

        """)
    }

    @Test(arguments: [
        ("Europe/Berlin", "2026-07-01T09:00:00+02:00"),
        ("Asia/Kolkata", "2026-07-01T12:30:00+05:30"),
        ("America/New_York", "2026-07-01T03:00:00-04:00")
    ])
    func timestampCarriesTheOffsetOfTheTimeZone(_ identifier: String, _ expected: String) throws {
        let at = zone.date(2026, 7, 1, 9)
        let zoneOfExport = try #require(TimeZone(identifier: identifier))
        let lines = csv([.done(.water, 1, at: at)], zoneOfExport).split(separator: "\n")
        #expect(lines.last == "\(expected),water,done,1")
    }

    @Test(arguments: [(1.0, "1"), (0.25, "0.25"), (15.0, "15"), (1.5, "1.5"), (0.12, "0.12"), (2.75, "2.75"), (0.0, "0")])
    func amountIsTheShortestDecimal(_ amount: Double, _ expected: String) {
        let lines = csv([.done(.water, amount, at: zone.date(2026, 3, 4, 10))]).split(separator: "\n")
        #expect(lines.last == "2026-03-04T10:00:00+01:00,water,done,\(expected)")
    }

    @Test func outputEndsWithExactlyOneNewline() {
        let text = csv([.done(.water, 1, at: zone.date(2026, 3, 4, 10)), .done(.water, 1, at: zone.date(2026, 3, 4, 12))])
        #expect(text.hasSuffix("\n"))
        #expect(!text.hasSuffix("\n\n"))
        #expect(text.filter { $0 == "\n" }.count == 3)
    }
}
