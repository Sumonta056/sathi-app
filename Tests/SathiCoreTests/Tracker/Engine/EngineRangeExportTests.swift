import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine range export")
struct EngineRangeExportTests {
    private func week(_ h: EngineHarness) -> StatsRange {
        var cal = Calendar.current
        cal.firstWeekday = 2
        return .containing(h.clock.now, kind: .week, calendar: cal)
    }

    private func harness() -> EngineHarness {
        let a = Activity(text: "Code review", category: "Coding", start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 10))
        let b = Activity(text: "Old", category: "Coding", start: day(2026, 2, 27, 9), end: day(2026, 2, 27, 10))
        let c = Activity(text: "Early", category: "Coding", start: day(2026, 3, 2, 9), end: day(2026, 3, 2, 10))
        return EngineHarness.tracker(at: day(2026, 3, 4, 12), activities: [a, b, c])
    }

    @Test func activitiesOfARangeAcrossTwoMonthsAreCollected() {
        let a = Activity(text: "Mar", start: day(2026, 3, 2, 9), end: day(2026, 3, 2, 10))
        let b = Activity(text: "Feb", start: day(2026, 2, 27, 9), end: day(2026, 2, 27, 10))
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 12), activities: [a, b])
        let month = StatsRange.containing(h.clock.now, kind: .month, calendar: .current)
        #expect(h.engine.activityDays(in: month).map(\.day.raw) == ["2026-03-02"])
        #expect(h.engine.activityDays(in: month.previous).map(\.day.raw) == ["2026-02-27"])
    }

    @Test func todayCarriesTheRunningActivity() {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10))
        h.engine.startActivity(h.work("Focus"))
        h.advance(minutes: 20)
        let days = h.engine.activityDays(in: week(h))
        #expect(days.count == 1)
        #expect(days[0].running != nil)
    }

    @Test func exportsOnlyTheActivitiesOfTheRange() throws {
        let h = harness()
        let folder = makeTempFolder()
        let url = try #require(h.engine.exportActivities(week(h), to: folder).url)
        #expect(url.lastPathComponent == ActivityRangeExporter.fileName(week(h), calendar: .current))
        let text = try #require(readText(url))
        #expect(text.contains("Code review") && text.contains("Early") && !text.contains("Old"))
        try? FileManager.default.removeItem(at: folder)
    }

    @Test func aSecondExportGetsAFreeName() throws {
        let h = harness()
        let folder = makeTempFolder()
        let first = try #require(h.engine.exportActivities(week(h), to: folder).url)
        let second = try #require(h.engine.exportActivities(week(h), to: folder).url)
        #expect(first != second)
        #expect(second.lastPathComponent == first.deletingPathExtension().lastPathComponent + " (2).csv")
        #expect(fileExists(first) && fileExists(second))
        try? FileManager.default.removeItem(at: folder)
    }

    @Test func anEmptyRangeWritesNothing() {
        let h = harness()
        let folder = makeTempFolder()
        let empty = week(h).previous.previous
        #expect(h.engine.exportActivities(empty, to: folder) == .empty)
        #expect(h.engine.exportHistory(empty, to: folder) == .empty)
        #expect(!fileExists(folder))
    }

    @Test func historyExportHoldsTheEventsOfTheRange() throws {
        let inside = HistoryEvent.done(.water, 1, at: day(2026, 3, 3, 10))
        let outside = HistoryEvent.done(.water, 1, at: day(2026, 2, 20, 10))
        let h = EngineHarness(at: day(2026, 3, 4, 12)) { $0.events = [inside, outside] }
        let folder = makeTempFolder()
        let url = try #require(h.engine.exportHistory(week(h), to: folder).url)
        #expect(url.lastPathComponent == HistoryRangeExporter.fileName(week(h), calendar: .current))
        let lines = try #require(readText(url)).split(separator: "\n")
        #expect(lines.count == 2)
        try? FileManager.default.removeItem(at: folder)
    }

    @Test func aFolderThatCannotBeWrittenFails() {
        let h = harness()
        #expect(h.engine.exportActivities(week(h), to: URL(fileURLWithPath: "/dev/null/nope")) == .failed)
    }
}
