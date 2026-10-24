import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("FileHistoryStore failures")
struct FileHistoryStoreFailureTests {
    private let base = makeTempFolder()
    private let first = HistoryEvent.done(.water, 1, at: day(2026, 10, 2, 10))
    private let later = HistoryEvent.done(.reading, 15, at: day(2026, 10, 20, 22))
    private let october = (day(2026, 10, 1), day(2026, 11, 1))

    private var folder: URL { base.appendingPathComponent("history") }
    private var monthURL: URL { folder.appendingPathComponent("2026-10.json") }
    private var corruptURL: URL { folder.appendingPathComponent("2026-10.json.corrupt") }

    private func store() -> FileHistoryStore { FileHistoryStore(base: base, calendar: .current, delay: 3600) }

    @Test func flushWithNothingPendingReturnsTrue() {
        #expect(store().flush())
    }

    @Test func unreadableMonthFileIsNeverOverwritten() throws {
        let s = store()
        s.append(first)
        s.flush()
        let before = try #require(readData(monthURL))
        try setPermissions(0o000, monthURL)
        defer { try? setPermissions(0o600, monthURL) }
        let unreadable = store()
        #expect(unreadable.events(from: october.0, to: october.1).isEmpty)
        unreadable.append(later)
        #expect(!unreadable.flush())
        try setPermissions(0o600, monthURL)
        #expect(readData(monthURL) == before)
        #expect(!fileExists(corruptURL))
    }

    @Test func failedWriteIsKeptAndWrittenByTheNextFlush() throws {
        try makeFolder(folder)
        defer { try? setPermissions(0o700, folder) }
        let s = store()
        try setPermissions(0o500, folder)
        s.append(first)
        #expect(!s.flush())
        try setPermissions(0o700, folder)
        #expect(s.flush())
        #expect(store().events(from: october.0, to: october.1) == [first])
    }

    @Test func corruptMonthReplacesAnOlderCorruptCopy() throws {
        try writeText("old", to: corruptURL)
        try writeText("new garbage", to: monthURL)
        #expect(store().events(from: october.0, to: october.1).isEmpty)
        #expect(readText(corruptURL) == "new garbage")
    }

    @Test func failedQuarantineKeepsBothFilesAndBlocksWrites() throws {
        try writeText("old", to: corruptURL)
        try writeText("new garbage", to: monthURL)
        defer { try? setPermissions(0o700, folder) }
        try setPermissions(0o500, folder)
        let s = store()
        #expect(s.events(from: october.0, to: october.1).isEmpty)
        try setPermissions(0o700, folder)
        s.append(later)
        s.flush()
        #expect(readText(monthURL) == "new garbage")
        #expect(readText(corruptURL) == "old")
    }
}
