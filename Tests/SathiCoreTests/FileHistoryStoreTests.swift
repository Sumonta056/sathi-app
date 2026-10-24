import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("FileHistoryStore")
struct FileHistoryStoreTests {
    private let base = makeTempFolder()
    private let octLate = HistoryEvent.done(.water, 1, at: day(2026, 10, 31, 23, 59))
    private let novEarly = HistoryEvent.done(.reading, 15, at: day(2026, 11, 1, 0, 1))

    private func store() -> FileHistoryStore { FileHistoryStore(base: base, calendar: .current) }
    private func monthFile(_ name: String) -> URL { base.appendingPathComponent("history").appendingPathComponent(name) }

    @Test func eventsLandInTheFileOfTheirMonth() throws {
        let s = store()
        s.append(octLate)
        s.append(novEarly)
        #expect(s.flush())
        let oct = try #require(readJSONObject(monthFile("2026-10.json")))
        #expect(oct["schemaVersion"] as? Int == 1)
        #expect((oct["value"] as? [Any])?.count == 1)
        let nov = try #require(readJSONObject(monthFile("2026-11.json")))
        #expect(nov["schemaVersion"] as? Int == 1)
        #expect((nov["value"] as? [Any])?.count == 1)
    }

    @Test func rangeAcrossMonthsReturnsBothSorted() {
        let s = store()
        s.append(novEarly)
        s.append(octLate)
        s.flush()
        #expect(store().events(from: day(2026, 10, 1), to: day(2026, 12, 1)) == [octLate, novEarly])
    }

    @Test func rangeInsideOneMonthReturnsOnlyThatMonth() {
        let s = store()
        s.append(octLate)
        s.append(novEarly)
        s.flush()
        #expect(store().events(from: day(2026, 10, 1), to: day(2026, 11, 1)) == [octLate])
    }

    @Test func rangeStartIsInclusiveAndEndIsExclusive() {
        let s = store()
        let at = day(2026, 10, 10, 12)
        let event = HistoryEvent.snooze(.water, at: at)
        s.append(event)
        s.flush()
        let reopened = store()
        #expect(reopened.events(from: day(2026, 10, 1), to: at).isEmpty)
        #expect(reopened.events(from: at, to: day(2026, 10, 10, 12, 1)) == [event])
    }

    @Test func appendedEventsAreReadableBeforeFlush() {
        let s = store()
        s.append(octLate)
        #expect(s.events(from: day(2026, 10, 1), to: day(2026, 11, 1)) == [octLate])
    }

    @Test func noFileIsWrittenBeforeFlush() {
        let s = FileHistoryStore(base: base, calendar: .current, delay: 3600)
        s.append(octLate)
        #expect(!fileExists(monthFile("2026-10.json")))
        s.flush()
        #expect(fileExists(monthFile("2026-10.json")))
    }

    @Test func appendingToAMonthKeepsItsEarlierEvents() {
        let first = HistoryEvent.done(.water, 1, at: day(2026, 10, 2, 10))
        let s = store()
        s.append(first)
        s.flush()
        let reopened = store()
        reopened.append(octLate)
        reopened.flush()
        #expect(store().events(from: day(2026, 10, 1), to: day(2026, 11, 1)) == [first, octLate])
    }

    @Test func corruptMonthFileIsRenamedAndReturnsNoEventsForThatMonth() throws {
        try writeText("garbage", to: monthFile("2026-10.json"))
        let s = store()
        s.append(novEarly)
        s.flush()
        #expect(store().events(from: day(2026, 10, 1), to: day(2026, 12, 1)) == [novEarly])
        #expect(readText(monthFile("2026-10.json.corrupt")) == "garbage")
    }
}
