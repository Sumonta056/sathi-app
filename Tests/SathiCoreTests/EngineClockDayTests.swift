import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine clock day")
struct EngineClockDayTests {
    @Test func justAfterMidnightWithoutATickStreakAndReportUseTheNewDay() {
        let h = EngineHarness(at: day(2026, 3, 4, 23, 59)) {
            $0.events = [.done(.water, 8, at: day(2026, 3, 2, 12)), .done(.water, 8, at: day(2026, 3, 3, 12))]
        }
        #expect(h.engine.streak(.water) == 2)
        h.clock.advance(minutes: 2)
        #expect(h.engine.report(.day).interval.start == day(2026, 3, 5))
        #expect(h.engine.streak(.water) == 0)
    }

    @Test func exportedAtIsAWholeSecondOfTheClock() async throws {
        let h = EngineHarness(at: day(2026, 3, 4, 10).addingTimeInterval(0.75))
        let folder = makeTempFolder()
        try makeFolder(folder)
        let url = folder.appendingPathComponent("backup.json")
        let outcome = await h.engine.export(
            .json,
            screen: h.engine.reportScreen(.day, selected: .water),
            to: SpyFileExporter(url: url),
            renderer: SpySummaryRenderer()
        )
        #expect(outcome == .saved(url))
        let data = try #require(readData(url))
        let backup = try #require(DecodedBackup.decode(data))
        #expect(backup.exportedAt == day(2026, 3, 4, 10))
    }
}
