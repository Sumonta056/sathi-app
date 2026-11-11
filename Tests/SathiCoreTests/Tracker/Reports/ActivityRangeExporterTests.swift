import Foundation
@testable import SathiCore
import Testing

@Suite("Activity range exporter")
struct ActivityRangeExporterTests {
    typealias Fix = ActivityReportSupport

    @Test func csvHasTheMonthColumnsAndIsSortedByStart() {
        let late = Fix.work("Late", "Coding", 5, (14, 0), (15, 0))
        let early = Fix.work("Early, with comma", nil, 4, (9, 0), (9, 30))
        let csv = ActivityRangeExporter.csv([late, early], timeZone: Fix.zone.timeZone)
        let lines = csv.split(separator: "\n").map(String.init)
        #expect(lines[0] == "start,end,minutes,kind,category,text,place")
        #expect(lines[1] == "2026-03-04T09:00:00+01:00,2026-03-04T09:30:00+01:00,30,work,,\"Early, with comma\",")
        #expect(lines[2].contains(",60,work,Coding,Late,"))
    }

    @Test func formulaStartsAreDefused() {
        let csv = ActivityRangeExporter.csv([Fix.work("=SUM(A1)", nil, 4, (9, 0), (10, 0))], timeZone: Fix.zone.timeZone)
        #expect(csv.contains(",'=SUM(A1),"))
    }

    @Test func fileNameHoldsTheFirstAndLastDayKey() {
        let week = StatsRange.containing(Fix.at(4, 12), kind: .week, calendar: Fix.calendar)
        #expect(ActivityRangeExporter.fileName(week, calendar: Fix.calendar) == "sathi-activities-2026-03-02-2026-03-08.csv")
        #expect(HistoryRangeExporter.fileName(week, calendar: Fix.calendar) == "sathi-history-2026-03-02-2026-03-08.csv")
    }

    @Test func aRangeAcrossTwoMonthsNamesBothMonths() {
        let week = StatsRange.containing(Fix.zone.date(2026, 3, 31, 12), kind: .week, calendar: Fix.calendar)
        #expect(ActivityRangeExporter.fileName(week, calendar: Fix.calendar) == "sathi-activities-2026-03-30-2026-04-05.csv")
    }

    @Test func aDayAndAMonthNameTheirDays() {
        let day = StatsRange.containing(Fix.at(4, 12), kind: .day, calendar: Fix.calendar)
        let month = StatsRange.containing(Fix.at(4, 12), kind: .month, calendar: Fix.calendar)
        #expect(ActivityRangeExporter.fileName(day, calendar: Fix.calendar) == "sathi-activities-2026-03-04-2026-03-04.csv")
        #expect(ActivityRangeExporter.fileName(month, calendar: Fix.calendar) == "sathi-activities-2026-03-01-2026-03-31.csv")
    }
}
