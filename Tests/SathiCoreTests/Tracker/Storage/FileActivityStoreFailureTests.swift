import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("FileActivityStore failures")
struct FileActivityStoreFailureTests {
    private let base = makeTempFolder()
    private var folder: URL { base.appendingPathComponent("activities") }
    private var file: URL { folder.appendingPathComponent("2026-11.json") }
    private var key: MonthKey { MonthKey(year: 2026, month: 11)! }

    private func item(_ text: String) -> Activity {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        return Activity(text: text, start: start, end: start.addingTimeInterval(600))
    }

    @Test func anUnreadableMonthIsNeverOverwritten() throws {
        try writeText(#"{"schemaVersion":1,"value":[]}"#, to: file)
        try setPermissions(0o000, file)
        defer { try? setPermissions(0o644, file) }
        let s = FileActivityStore(base: base, delay: 3600)
        #expect(s.month(key).items.isEmpty)
        s.save(ActivityMonth(key: key, items: [item("Plan")]))
        #expect(!s.flush())
        try setPermissions(0o644, file)
        #expect(readText(file) == #"{"schemaVersion":1,"value":[]}"#)
        #expect(s.month(key).items.map(\.text) == ["Plan"])
    }

    @Test func aFailedWriteStaysPendingAndIsWrittenByALaterFlush() throws {
        try makeFolder(folder)
        try setPermissions(0o500, folder)
        defer { try? setPermissions(0o755, folder) }
        let s = FileActivityStore(base: base, delay: 3600)
        s.save(ActivityMonth(key: key, items: [item("Plan")]))
        #expect(!s.flush())
        try setPermissions(0o755, folder)
        #expect(s.flush())
        #expect(FileActivityStore(base: base, delay: 3600).month(key).items.map(\.text) == ["Plan"])
    }

    @Test func foreignFilesInTheFolderAreIgnored() throws {
        try writeText("x", to: folder.appendingPathComponent("notes.json"))
        try writeText("x", to: folder.appendingPathComponent("2026-13.json"))
        #expect(FileActivityStore(base: base, delay: 3600).savedMonths().isEmpty)
    }
}
