import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Gregorian dates")
struct GregorianTests {
    private let zone = FixedZone.berlin
    private let buddhist = FixedZone("Europe/Berlin", calendar: .buddhist).calendar
    private let base = makeTempFolder()

    @Test(arguments: [
        (ExportFormat.csv, "Sathi-history-2026-03-04.csv"),
        (.json, "Sathi-backup-2026-03-04.json"),
        (.pdf, "Sathi-summary-2026-03-04.pdf")
    ])
    func exportNamesUseGregorianYears(_ format: ExportFormat, _ expected: String) {
        #expect(ExportNames.fileName(format, on: zone.date(2026, 3, 4, 10), calendar: buddhist) == expected)
    }

    @Test func monthReportRunsFromMarchFirstToAprilFirst() {
        let report = ReportBuilder(calendar: buddhist).build(.month, now: zone.date(2026, 3, 4, 10), events: [], prefs: Prefs())
        #expect(report.interval == DateInterval(start: zone.date(2026, 3, 1), end: zone.date(2026, 4, 1)))
        #expect(report.habits.first?.buckets.count == 31)
    }

    @Test func historyFilesUseGregorianMonthNames() {
        let store = FileHistoryStore(base: base, calendar: buddhist)
        let event = HistoryEvent.done(.water, 1, at: zone.date(2026, 10, 15, 10))
        store.append(event)
        #expect(store.flush())
        let folder = base.appendingPathComponent(StorageKeys.historyFolder)
        #expect(fileExists(folder.appendingPathComponent("2026-10.json")))
        #expect(!fileExists(folder.appendingPathComponent("2569-10.json")))
        #expect(FileHistoryStore(base: base, calendar: buddhist).events(from: zone.date(2026, 10, 1), to: zone.date(2026, 11, 1)) == [event])
    }

    @Test func historyFilesWrittenWithGregorianAreReadWithBuddhist() {
        let event = HistoryEvent.done(.water, 1, at: zone.date(2026, 10, 15, 10))
        let writer = FileHistoryStore(base: base, calendar: zone.calendar)
        writer.append(event)
        writer.flush()
        #expect(FileHistoryStore(base: base, calendar: buddhist).allEvents() == [event])
        #expect(FileHistoryStore(base: base, calendar: buddhist).events(from: zone.date(2026, 10, 1), to: zone.date(2026, 11, 1)) == [event])
    }

    @Test func csvTimestampYearIsGregorian() {
        let text = CSVExporter.csv([.done(.water, 1, at: zone.date(2026, 3, 4, 10))], timeZone: buddhist.timeZone)
        #expect(text.hasSuffix("2026-03-04T10:00:00+01:00,water,done,1\n"))
    }

    @Test func engineExportNameIsGregorianWithABuddhistCalendar() async throws {
        try makeFolder(base)
        let url = base.appendingPathComponent("history.csv")
        let spy = SpyFileExporter(url: url)
        let engine = Engine(
            store: InMemoryStateStore(),
            history: InMemoryHistoryStore(events: [.done(.water, 1, at: zone.date(2026, 3, 4, 9))]),
            clock: FakeClock(zone.date(2026, 3, 4, 10)),
            sound: SpySoundPlayer(),
            presenter: SpyPresenter(),
            calendar: buddhist
        )
        let outcome = await engine.export(.csv, screen: engine.reportScreen(.week, selected: .water), to: spy, renderer: SpySummaryRenderer())
        #expect(outcome == .saved(url))
        #expect(spy.requests.first?.suggestedName == "Sathi-history-2026-03-04.csv")
        #expect(readText(url)?.contains("2026-03-04T09:00:00+01:00,water,done,1") == true)
    }

    @Test func streakAcrossAMonthBoundaryWorksWithABuddhistCalendar() {
        let now = zone.date(2026, 4, 3, 12)
        let store = InMemoryHistoryStore(events: zone.doneDays(.water, 8, count: 10, endingAt: now))
        let streak = StreakCalculator(calendar: buddhist)
            .current(.water, goal: 8, reset: nil, now: now) { store.events(from: $0.start, to: $0.end) }
        #expect(streak == 10)
    }
}
