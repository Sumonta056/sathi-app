import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("History range export")
struct HistoryRangeExportTests {
    @Test func fileNameStartsWithTheHistoryPrefixAndHoldsBothDays() {
        let zone = FixedZone.berlin
        let range = StatsRange.containing(zone.date(2026, 3, 31, 12), kind: .week, calendar: zone.calendar)
        let name = HistoryRangeExporter.fileName(range, calendar: zone.calendar)
        #expect(name == StorageKeys.exportHistoryRangePrefix + "2026-03-30-2026-04-05.csv")
    }

    @Test func prefixesAreTheLowercaseNamesOfTheBrief() {
        #expect(StorageKeys.exportHistoryRangePrefix == "sathi-history-")
        #expect(StorageKeys.exportActivitiesRangePrefix == "sathi-activities-")
    }
}
