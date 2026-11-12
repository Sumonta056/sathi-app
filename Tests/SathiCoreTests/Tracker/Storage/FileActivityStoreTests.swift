import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("FileActivityStore")
struct FileActivityStoreTests {
    private let base = makeTempFolder()
    private let zone = FixedZone("UTC")

    private var folder: URL { base.appendingPathComponent("activities") }
    private var november: URL { folder.appendingPathComponent("2026-11.json") }
    private var key: MonthKey { MonthKey(year: 2026, month: 11)! }

    private func store() -> FileActivityStore { FileActivityStore(base: base, delay: 3600) }

    private func item(_ text: String, day: Int = 9, hour: Int = 9, offset: TimeInterval = 0) -> Activity {
        let start = zone.date(2026, 11, day, hour).addingTimeInterval(offset)
        return Activity(text: text, category: "Coding", start: start, end: start.addingTimeInterval(1800))
    }

    @Test func nothingIsWrittenBeforeFlush() {
        let s = store()
        s.save(ActivityMonth(key: key, items: [item("Plan")]))
        #expect(!fileExists(november))
        #expect(s.flush())
        #expect(fileExists(november))
    }

    @Test func aSavedMonthLoadsBackInANewStore() {
        let s = store()
        let month = ActivityMonth(key: key, items: [item("Plan"), item("Review", hour: 11)])
        s.save(month)
        s.flush()
        #expect(store().month(key) == month)
    }

    @Test func aMissingMonthIsEmptyAndWritesNoFile() {
        let s = store()
        #expect(s.month(key).items.isEmpty)
        s.flush()
        #expect(!fileExists(november))
        #expect(s.savedMonths().isEmpty)
    }

    @Test func fileIsVersionedAndTimesAreWholeSeconds() throws {
        let s = store()
        s.save(ActivityMonth(key: key, items: [item("Plan", offset: 0.7)]))
        s.flush()
        let json = try #require(readJSONObject(november))
        #expect(json["schemaVersion"] as? Int == Limits.schemaVersion)
        let text = try #require(readText(november))
        #expect(!text.contains("."))
    }

    @Test func aMutatedFractionalTimeIsRoundedOnSave() {
        var a = item("Plan")
        a.start = a.start.addingTimeInterval(0.9)
        let s = store()
        s.save(ActivityMonth(key: key, items: [a]))
        s.flush()
        #expect(store().month(key).items[0].start == a.start.wholeSecond)
    }

    @Test func savedMonthsListsFilesAndPendingMonths() throws {
        let s = store()
        let oct = try #require(MonthKey(year: 2026, month: 10))
        s.save(ActivityMonth(key: key, items: [item("Plan")]))
        s.save(ActivityMonth(key: oct, items: [item("Old")]))
        #expect(s.savedMonths() == [oct, key])
        s.flush()
        #expect(store().savedMonths() == [oct, key])
    }

    @Test func allActivitiesAreSortedAcrossMonths() throws {
        let s = store()
        let oct = try #require(MonthKey(year: 2026, month: 10))
        s.save(ActivityMonth(key: key, items: [item("New")]))
        s.save(ActivityMonth(key: oct, items: [item("Old")]))
        s.flush()
        #expect(store().allActivities().map(\.text) == ["Old", "New"])
    }

    @Test func savingAnEmptyMonthDeletesNothingElse() {
        let s = store()
        s.save(ActivityMonth(key: key, items: [item("Plan")]))
        s.flush()
        s.save(ActivityMonth(key: key, items: []))
        s.flush()
        #expect(store().month(key).items.isEmpty)
    }

    @Test func monthFilesAreKeptWhenOtherMonthsAreWritten() throws {
        let s = store()
        s.save(ActivityMonth(key: key, items: [item("Plan")]))
        s.flush()
        let dec = try #require(MonthKey(year: 2026, month: 12))
        s.save(ActivityMonth(key: dec, items: [item("Later")]))
        s.flush()
        #expect(store().month(key).items.map(\.text) == ["Plan"])
    }
}
