import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("FileActivityStore backup")
struct FileActivityStoreBackupTests {
    private let base = makeTempFolder()
    private let zone = FixedZone("UTC")

    private var folder: URL { base.appendingPathComponent("activities") }
    private var file: URL { folder.appendingPathComponent("2026-11.json") }
    private var backupFile: URL { folder.appendingPathComponent("2026-11.backup.json") }
    private var key: MonthKey { MonthKey(year: 2026, month: 11)! }

    private func store() -> FileActivityStore { FileActivityStore(base: base, delay: 3600) }

    private func item(_ text: String, hour: Int = 9) -> Activity {
        let start = zone.date(2026, 11, 9, hour)
        return Activity(text: text, category: "Coding", start: start, end: start.addingTimeInterval(1800))
    }

    private let fileWithUnknowns = #"{"schemaVersion":1,"value":[{"id":"6F1C0C1E-3D0B-4E55-9C59-1B7B7A1B0001","kind":"work","# +
        #""text":"Plan","start":"2026-11-09T09:00:00Z","end":"2026-11-09T09:30:00Z","mood":"calm"},{"future":true}]}"#

    @Test func backupWritesTheSameJSONAsTheMonthFile() throws {
        let s = store()
        s.save(ActivityMonth(key: key, items: [item("Plan"), item("Review", hour: 11)]))
        s.flush()
        #expect(store().backup(key))
        let original = try #require(readData(file))
        #expect(readData(backupFile) == original)
    }

    @Test func backupCopiesTheOriginalBytesWithUnknownData() throws {
        try writeText(fileWithUnknowns, to: file)
        let s = store()
        #expect(s.month(key).items.map(\.text) == ["Plan"])
        #expect(s.backup(key))
        #expect(readText(backupFile) == fileWithUnknowns)
    }

    @Test func backupFilesAreNotListedAsMonths() {
        let s = store()
        s.save(ActivityMonth(key: key, items: [item("Plan")]))
        s.flush()
        #expect(s.backup(key))
        #expect(fileExists(backupFile))
        #expect(store().savedMonths() == [key])
        #expect(store().allActivities().map(\.text) == ["Plan"])
    }

    @Test func anExistingBackupIsNeverOverwritten() throws {
        try writeText("first", to: backupFile)
        let s = store()
        s.save(ActivityMonth(key: key, items: [item("Plan")]))
        s.flush()
        #expect(s.backup(key))
        #expect(readText(backupFile) == "first")
    }

    @Test func anUnreadableMonthIsNotBackedUp() throws {
        try writeText(#"{"schemaVersion":1,"value":[]}"#, to: file)
        try setPermissions(0o000, file)
        defer { try? setPermissions(0o644, file) }
        #expect(!store().backup(key))
        #expect(!fileExists(backupFile))
    }
}
