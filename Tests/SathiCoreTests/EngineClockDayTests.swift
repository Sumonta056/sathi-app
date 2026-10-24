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

    @Test func exportedAtIsAWholeSecondOfTheClock() throws {
        let h = EngineHarness(at: day(2026, 3, 4, 10).addingTimeInterval(0.75))
        let spy = SpyFileExporter()
        _ = h.engine.export(.json, to: spy)
        let save = try #require(spy.saves.first)
        let backup = try #require(DecodedBackup.decode(save.data))
        #expect(backup.exportedAt == day(2026, 3, 4, 10))
    }
}
