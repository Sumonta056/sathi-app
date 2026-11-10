import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("Activity place name storage")
struct ActivityPlaceNameStorageTests {
    private let base = makeTempFolder()
    private let zone = FixedZone("UTC")
    private let id = "11111111-1111-1111-1111-111111111111"

    private var november: URL { base.appendingPathComponent("activities/2026-11.json") }
    private var key: MonthKey { MonthKey(year: 2026, month: 11)! }

    private func store() -> FileActivityStore { FileActivityStore(base: base, delay: 3600) }

    private func decode(_ json: String) throws -> Activity {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return try d.decode(Activity.self, from: Data(json.utf8))
    }

    private func item(_ fields: String) -> String {
        #"{"id":"\#(id)","kind":"away","text":"Away · Doctor","awayPlace":"other","# + fields
            + #""start":"2026-11-09T12:00:00Z","end":"2026-11-09T13:00:00Z"}"#
    }

    private func away(name: String?, place: AwayPlace? = .other, hour: Int = 12) -> Activity {
        let start = zone.date(2026, 11, 9, hour)
        return Activity(
            kind: .away, text: Copywriter.trackerAwayText(place, name: name), start: start,
            end: start.addingTimeInterval(3600), awayPlace: place, awayPlaceName: name
        )
    }

    private func csv(_ items: [Activity]) -> [String] {
        ActivityMonthExporter.csv(ActivityMonth(key: key, items: items), timeZone: zone.timeZone)
            .split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
    }

    @Test func theDefaultIsNoName() {
        let a = Activity(text: "Plan", start: zone.date(2026, 11, 9, 9), end: zone.date(2026, 11, 9, 10))
        #expect(a.awayPlaceName == nil)
        #expect(AwaySpan(start: a.start, end: a.end, cause: .locked).placeName == nil)
        #expect(ActivityEdit(text: "", category: nil, start: a.start, end: a.end).awayPlaceName == nil)
    }

    @Test func oldJSONWithoutTheKeyLoadsNoNameAndKeepsTheRest() throws {
        let a = try decode(item(""))
        #expect(a.awayPlaceName == nil)
        #expect(a.awayPlace == .other)
        #expect(a.text == "Away · Doctor")
        #expect(a.start == zone.date(2026, 11, 9, 12))
    }

    @Test func theKeyLoadsTheName() throws {
        #expect(try decode(item(#""awayPlaceName":"Doctor","#)).awayPlaceName == "Doctor")
    }

    @Test(arguments: ["7", "true", #"["Doctor"]"#, "null"])
    func aWrongTypeLoadsNoNameAndKeepsTheItem(_ bad: String) throws {
        let a = try decode(item(#""awayPlaceName":"# + bad + ","))
        #expect(a.awayPlaceName == nil)
        #expect(a.awayPlace == .other)
        #expect(a.text == "Away · Doctor")
    }

    @Test func theNameRoundTrips() throws {
        let a = away(name: "Doctor")
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        let data = try e.encode(a)
        let back = try decode(#require(String(bytes: data, encoding: .utf8)))
        #expect(back == a)
        #expect(back.awayPlaceName == "Doctor")
    }

    @Test func aSavedMonthKeepsTheNameInANewStore() {
        let s = store()
        let month = ActivityMonth(key: key, items: [away(name: "Doctor"), away(name: nil, place: .lunch, hour: 14)])
        s.save(month)
        #expect(s.flush())
        #expect(store().month(key) == month)
        #expect(store().month(key).items.map(\.awayPlaceName) == ["Doctor", nil])
        #expect(readText(november)?.contains(#""awayPlaceName":"Doctor""#) == true)
    }

    @Test func anOldMonthFileWithoutTheKeyLoadsAndSavesBackWithoutLoss() throws {
        try writeText(#"{"schemaVersion":1,"value":["# + item("") + "]}", to: november)
        let s = store()
        let loaded = s.month(key)
        #expect(loaded.items.map(\.awayPlaceName) == [nil])
        #expect(loaded.items.map(\.text) == ["Away · Doctor"])
        s.save(loaded)
        #expect(s.flush())
        #expect(store().month(key) == loaded)
    }

    @Test func activityAwayTextNamesTheNameThenThePlace() {
        #expect(away(name: "Doctor").awayText == "Away · Doctor")
        #expect(away(name: nil, place: .lunch).awayText == "Away · Lunch")
        #expect(away(name: nil, place: .other).awayText == "Away · Other")
        #expect(away(name: nil, place: nil).awayText == "Away")
    }

    @Test func theLastCSVColumnIsTheNameWhenThereIsOne() {
        let lines = csv([away(name: "Doctor")])
        #expect(lines[0] == "start,end,minutes,kind,category,text,place")
        #expect(lines[1] == "2026-11-09T12:00:00+00:00,2026-11-09T13:00:00+00:00,60,away,,Away · Doctor,Doctor")
    }

    @Test func theLastCSVColumnIsTheRawPlaceWithoutAName() {
        let lines = csv([away(name: nil, place: .other), away(name: nil, place: .breakTime, hour: 14), away(name: nil, place: nil, hour: 16)])
        #expect(lines[1].hasSuffix(",away,,Away · Other,other"))
        #expect(lines[2].hasSuffix(",away,,Away · Break,break"))
        #expect(lines[3].hasSuffix(",away,,Away,"))
    }

    @Test func theMonthJSONExportHoldsTheName() throws {
        let month = ActivityMonth(key: key, items: [away(name: "Doctor")])
        let data = ActivityMonthExporter.json(month, exportedAt: zone.date(2026, 12, 1, 8))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let items = try #require(json["items"] as? [[String: Any]])
        #expect(items.map { $0["awayPlaceName"] as? String } == ["Doctor"])
    }
}
