import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("ActivityMonthExporter")
struct ActivityMonthExporterTests {
    private let zone = FixedZone("UTC")
    private var key: MonthKey { MonthKey(year: 2026, month: 11)! }

    private func item(_ text: String, hour: Int, category: String? = "Coding", place: AwayPlace? = nil) -> Activity {
        let start = zone.date(2026, 11, 9, hour)
        return Activity(
            kind: place == nil ? .work : .away,
            text: text,
            category: category,
            start: start,
            end: start.addingTimeInterval(5400),
            awayPlace: place
        )
    }

    private func csv(_ items: [Activity]) -> [String] {
        ActivityMonthExporter.csv(ActivityMonth(key: key, items: items), timeZone: zone.timeZone)
            .split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    @Test func csvHasAHeaderAndOneSortedRowPerItem() {
        let lines = csv([item("Later", hour: 14), item("Plan", hour: 9)])
        #expect(lines[0] == "start,end,minutes,kind,category,text,place")
        #expect(lines[1] == "2026-11-09T09:00:00+00:00,2026-11-09T10:30:00+00:00,90,work,Coding,Plan,")
        #expect(lines[2].contains(",Later,"))
        #expect(lines.count == 3)
    }

    @Test func emptyMonthIsOnlyTheHeader() {
        #expect(csv([]) == ["start,end,minutes,kind,category,text,place"])
    }

    @Test func csvQuotesCommasAndQuotesAndFlattensNewlines() {
        let lines = csv([item("a, \"b\"\nc", hour: 9)])
        #expect(lines.count == 2)
        #expect(lines[1].hasSuffix(#","a, ""b"" c","#))
    }

    @Test func csvDefusesSpreadsheetFormulas() {
        let lines = csv([item("=SUM(A1)", hour: 9, category: "+x")])
        #expect(lines[1].contains(",'+x,'=SUM(A1),"))
    }

    @Test(arguments: ["\t=1+2", "\r=1+2", "\r\n=1+2"])
    func csvDefusesALeadingTabOrCarriageReturn(_ text: String) {
        let lines = csv([item(text, hour: 9)])
        #expect(lines.count == 2)
        let cell = lines[1].split(separator: ",", omittingEmptySubsequences: false)[5]
        #expect(cell.hasPrefix("'"))
    }

    @Test func csvShowsKindAndPlaceForAway() {
        let lines = csv([item("Lunch", hour: 12, category: nil, place: .lunch)])
        #expect(lines[1].hasSuffix(",away,,Lunch,lunch"))
    }

    @Test func jsonHoldsMonthVersionAndItemsSorted() throws {
        let month = ActivityMonth(key: key, items: [item("Later", hour: 14), item("Plan", hour: 9)])
        let data = ActivityMonthExporter.json(month, exportedAt: zone.date(2026, 12, 1, 8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["schemaVersion"] as? Int == Limits.schemaVersion)
        #expect(json["month"] as? String == "2026-11")
        #expect(json["exportedAt"] as? String == "2026-12-01T08:00:00Z")
        let items = try #require(json["items"] as? [[String: Any]])
        #expect(items.map { $0["text"] as? String } == ["Plan", "Later"])
    }

    @Test func fileNameUsesThePrefixMonthAndFormat() {
        #expect(ActivityMonthExporter.fileName(key, format: .csv) == "Sathi-activities-2026-11.csv")
        #expect(ActivityMonthExporter.fileName(key, format: .json) == "Sathi-activities-2026-11.json")
    }
}
