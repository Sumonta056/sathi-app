import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Reading list decoding")
struct ReadingListDecodingTests {
    private let id1 = "6F9619FF-8B86-D011-B42D-00C04FC964FF"
    private let id2 = "7A1B2C3D-8B86-D011-B42D-00C04FC964FF"

    private func decode(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func defaultListIsEmpty() {
        #expect(ReadingPrefs().list.isEmpty)
    }

    @Test func missingListKeyDecodesAsEmpty() throws {
        let p = try decode(#"{"general":{"name":"Asha"},"reading":{"timeMinutes":1260,"sessionMinutes":20}}"#)
        #expect(p.reading.list.isEmpty)
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.reading.sessionMinutes == 20)
        #expect(p.general.name == "Asha")
    }

    @Test func savedItemsDecodeInOrder() throws {
        let p = try decode(#"""
        {"reading":{"list":[
          {"id":"\#(id1)","title":"First","url":"https://a.com/post","addedOn":"2026-03-01"},
          {"id":"\#(id2)","title":"","url":"https://b.com/post","addedOn":"2026-02-01","doneOn":"2026-03-02"}
        ]}}
        """#)
        #expect(p.reading.list.count == 2)
        let first = try #require(p.reading.list.first)
        #expect(first.id == UUID(uuidString: id1))
        #expect(first.title == "First")
        #expect(first.url == URL(string: "https://a.com/post"))
        #expect(first.addedOn == DayKey(raw: "2026-03-01"))
        #expect(first.doneOn == nil)
        #expect(p.reading.list.last?.doneOn == DayKey(raw: "2026-03-02"))
    }

    @Test(arguments: [
        #"{"id":"not-a-uuid","title":"x","url":"https://x.com","addedOn":"2026-03-01"}"#,
        #"{"id":"7A1B2C3D-8B86-D011-B42D-00C04FC964FF","title":"x","addedOn":"2026-03-01"}"#,
        #"{"id":"7A1B2C3D-8B86-D011-B42D-00C04FC964FF","title":"x","url":"https://x.com","addedOn":"2026-13-45"}"#,
        #"{"id":"7A1B2C3D-8B86-D011-B42D-00C04FC964FF","title":"x","url":"https://x.com","addedOn":"2026-03-01","doneOn":"soon"}"#,
        #""just text""#,
        "42"
    ])
    func badItemIsDroppedAndTheRestStays(_ bad: String) throws {
        let p = try decode(#"""
        {"general":{"name":"Asha"},"reading":{"timeMinutes":1260,"weekdays":[2,3],"list":[
          {"id":"\#(id1)","title":"Keep","url":"https://a.com/post","addedOn":"2026-03-01"},
          \#(bad)
        ]}}
        """#)
        #expect(p.reading.list.map(\.title) == ["Keep"])
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.reading.weekdays == [.monday, .tuesday])
        #expect(p.general.name == "Asha")
    }

    @Test func listThatIsNotAnArrayDecodesAsEmptyAndTheRestStays() throws {
        let p = try decode(#"{"general":{"name":"Asha"},"reading":{"timeMinutes":1260,"list":"oops"}}"#)
        #expect(p.reading.list.isEmpty)
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.general.name == "Asha")
    }

    @Test func listSurvivesARoundTrip() throws {
        var p = Prefs()
        p.reading.list = try [
            ReadingItem(title: "First", url: #require(URL(string: "https://a.com/post")), addedOn: #require(DayKey(raw: "2026-03-01"))),
            ReadingItem(
                title: "",
                url: #require(URL(string: "file:///Users/asha/notes/a.pdf")),
                addedOn: #require(DayKey(raw: "2026-02-01")),
                doneOn: #require(DayKey(raw: "2026-03-02"))
            )
        ]
        let data = try JSONEncoder().encode(p)
        let back = try JSONDecoder().decode(Prefs.self, from: data)
        #expect(back == p)
        #expect(back.reading.list == p.reading.list)
    }

    @Test func listIsSavedUnderTheListKey() throws {
        var r = ReadingPrefs()
        r.list = try [ReadingItem(title: "First", url: #require(URL(string: "https://a.com/post")), addedOn: #require(DayKey(raw: "2026-03-01")))]
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(r)) as? [String: Any]
        let list = try #require(object?["list"] as? [[String: Any]])
        #expect(list.count == 1)
        #expect(list.first?["url"] as? String == "https://a.com/post")
        #expect(list.first?["addedOn"] as? String == "2026-03-01")
    }
}
