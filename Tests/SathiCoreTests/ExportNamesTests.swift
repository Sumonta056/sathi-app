import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("ExportNames")
struct ExportNamesTests {
    private let zone = FixedZone.berlin

    @Test(arguments: [
        (ExportFormat.csv, "Sathi-history-2026-03-04.csv"),
        (.json, "Sathi-backup-2026-03-04.json"),
        (.pdf, "Sathi-summary-2026-03-04.pdf")
    ])
    func fileNameUsesTheLocalDate(_ format: ExportFormat, _ expected: String) {
        #expect(ExportNames.fileName(format, on: zone.date(2026, 3, 4, 0, 30), calendar: zone.calendar) == expected)
    }

    @Test func theDateIsTheDateOfTheCalendarZone() {
        let lateEvening = FixedZone("America/New_York").date(2026, 3, 3, 23)
        #expect(ExportNames.fileName(.csv, on: lateEvening, calendar: zone.calendar) == "Sathi-history-2026-03-04.csv")
        #expect(ExportNames.fileName(.json, on: lateEvening, calendar: FixedZone.newYork.calendar) == "Sathi-backup-2026-03-03.json")
    }

    @Test func singleDigitMonthsAndDaysArePadded() {
        #expect(ExportNames.fileName(.csv, on: zone.date(2027, 1, 9, 12), calendar: zone.calendar) == "Sathi-history-2027-01-09.csv")
    }

    @Test func prefixesComeFromStorageKeys() {
        #expect(StorageKeys.exportHistoryPrefix == "Sathi-history-")
        #expect(StorageKeys.exportBackupPrefix == "Sathi-backup-")
        #expect(StorageKeys.exportSummaryPrefix == "Sathi-summary-")
    }
}
