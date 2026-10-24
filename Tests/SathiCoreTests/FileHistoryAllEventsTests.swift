import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("FileHistoryStore allEvents")
struct FileHistoryAllEventsTests {
    private let base = makeTempFolder()
    private let jan = HistoryEvent.done(.water, 1, at: day(2026, 1, 31, 23, 59))
    private let feb = HistoryEvent.snooze(.reading, at: day(2026, 2, 14, 22))
    private let mar = HistoryEvent.done(.meditation, 5, at: day(2026, 3, 1, 8))

    private func store(delay: TimeInterval = Timing.saveCoalesce) -> FileHistoryStore {
        FileHistoryStore(base: base, calendar: .current, delay: delay)
    }

    private func historyFile(_ name: String) -> URL { base.appendingPathComponent("history").appendingPathComponent(name) }

    private func writeMonths(_ events: [HistoryEvent]) {
        let s = store()
        events.forEach(s.append)
        s.flush()
    }

    @Test func eventsOfThreeMonthFilesComeBackSorted() {
        writeMonths([mar, jan, feb])
        #expect(store().allEvents() == [jan, feb, mar])
    }

    @Test func eventsInsideOneMonthAreSorted() {
        let early = HistoryEvent.done(.water, 2, at: day(2026, 2, 1, 9))
        writeMonths([feb, early])
        #expect(store().allEvents() == [early, feb])
    }

    @Test func aMissingFolderGivesNoEvents() {
        #expect(store().allEvents().isEmpty)
    }

    @Test func filesThatAreNotMonthFilesAreIgnored() throws {
        writeMonths([feb])
        let monthText = try #require(readText(historyFile("2026-02.json")))
        try writeText(monthText, to: historyFile("backup.json"))
        try writeText(monthText, to: historyFile("2026-02.json.bak"))
        try writeText(monthText, to: historyFile("notes.txt"))
        try writeText(monthText, to: historyFile("2026-2.json"))
        #expect(store().allEvents() == [feb])
    }

    @Test func pendingEventsAreIncluded() {
        writeMonths([feb])
        let s = store(delay: 3600)
        s.append(mar)
        s.append(jan)
        #expect(s.allEvents() == [jan, feb, mar])
    }

    @Test func aPendingEventInAMonthOnDiskIsNotDuplicated() {
        writeMonths([feb])
        let s = store(delay: 3600)
        let later = HistoryEvent.done(.water, 1, at: day(2026, 2, 20, 10))
        s.append(later)
        #expect(s.allEvents() == [feb, later])
    }

    @Test func anUnreadableMonthFileIsSkipped() throws {
        writeMonths([jan, mar])
        try writeText("garbage", to: historyFile("2026-02.json"))
        #expect(store().allEvents() == [jan, mar])
    }

    @Test func anUnreadableMonthStaysBlockedForWrites() throws {
        try writeText("[]", to: historyFile("2026-02.json"))
        try setPermissions(0o000, historyFile("2026-02.json"))
        defer { try? setPermissions(0o644, historyFile("2026-02.json")) }
        let s = store(delay: 3600)
        #expect(s.allEvents().isEmpty)
        s.append(feb)
        #expect(!s.flush())
    }
}
