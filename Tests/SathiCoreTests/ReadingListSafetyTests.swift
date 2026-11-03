import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Reading list safety")
struct ReadingListSafetyTests {
    private let id1 = "6F9619FF-8B86-D011-B42D-00C04FC964FF"
    private let id2 = "7A1B2C3D-8B86-D011-B42D-00C04FC964FF"
    private let id3 = "8B2C3D4E-8B86-D011-B42D-00C04FC964FF"

    private func decode(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    private func item(_ id: String, _ url: String, title: String = "t", done: String? = nil) -> String {
        let doneField = done.map { #","doneOn":"\#($0)""# } ?? ""
        return #"{"id":"\#(id)","title":"\#(title)","url":"\#(url)","addedOn":"2026-03-01"\#(doneField)}"#
    }

    @Test(arguments: [
        "javascript:alert(1)",
        "ssh://example.com/x",
        "x-apple.systempreferences:com.apple.preference.security",
        "file:",
        "file:foo",
        "file:///",
        "https:///nohost",
        "mailto:a@b.com"
    ])
    func decodeDropsAnUnsafeLinkAndKeepsTheRest(_ bad: String) throws {
        let p = try decode(#"""
        {"general":{"name":"Asha"},"reading":{"timeMinutes":1260,"list":[
          \#(item(id1, "https://a.com/post", title: "Keep")),
          \#(item(id2, bad)),
          \#(item(id3, "file:///Users/asha/a.pdf", title: "File"))
        ]}}
        """#)
        #expect(p.reading.list.map(\.title) == ["Keep", "File"])
        #expect(p.reading.timeMinutes == 1260)
        #expect(p.general.name == "Asha")
    }

    @Test func decodeDropsATooLongLink() throws {
        let long = "https://a.com/" + String(repeating: "x", count: Limits.readingURLMax)
        let p = try decode(#"{"reading":{"list":[\#(item(id1, long)),\#(item(id2, "https://b.com"))]}}"#)
        #expect(p.reading.list.count == 1)
    }

    @Test(arguments: ["javascript:alert(1)", "ssh://x", "x-apple.systempreferences:a", "file:foo"])
    func startReadingOpensNothingForAnUnsafePickButStartsTheSession(_ bad: String) throws {
        let url = try #require(URL(string: bad))
        let h = Shelf.harness([ReadingItem(title: "", url: url, addedOn: Shelf.today)])
        h.engine.startReading()
        #expect(h.links.opened.isEmpty)
        #expect(h.engine.session(.reading) != nil)
    }

    @Test func duplicateIdsKeepTheFirstOnly() throws {
        let p = try decode(#"""
        {"reading":{"list":[
          \#(item(id1, "https://a.com", title: "First")),
          \#(item(id1, "https://b.com", title: "Second")),
          \#(item(id2, "https://c.com", title: "Third"))
        ]}}
        """#)
        #expect(p.reading.list.map(\.title) == ["First", "Third"])
    }

    @Test func markingDoneNeverRemovesAnUnreadItemAfterADuplicateDecode() throws {
        let p = try decode(#"""
        {"reading":{"list":[
          \#(item(id1, "https://a.com", title: "First")),
          \#(item(id1, "https://b.com", title: "Second")),
          \#(item(id2, "https://c.com", title: "Third"))
        ]}}
        """#)
        let h = Shelf.harness(p.reading.list)
        try h.engine.markReadingDone(id: #require(UUID(uuidString: id1)))
        let titles = Shelf.list(h).map(\.title)
        #expect(titles == ["Third", "First"])
        #expect(Shelf.list(h).filter { $0.doneOn == nil }.count == 1)
    }

    @Test func decodeClampsLongTitles() throws {
        let long = String(repeating: "t", count: Limits.readingTitleMax + 30)
        let p = try decode(#"{"reading":{"list":[\#(item(id1, "https://a.com", title: long))]}}"#)
        #expect(p.reading.list.first?.title.count == Limits.readingTitleMax)
    }

    @Test func decodeOrdersUnreadFirstThenReadNewestFirstStable() throws {
        let p = try decode(#"""
        {"reading":{"list":[
          \#(item(id1, "https://old.com", title: "oldRead", done: "2026-03-01")),
          \#(item(id2, "https://u1.com", title: "u1")),
          \#(item(id3, "https://new.com", title: "newRead", done: "2026-03-03")),
          \#(item("9C3D4E5F-8B86-D011-B42D-00C04FC964FF", "https://u2.com", title: "u2")),
          \#(item("AD4E5F60-8B86-D011-B42D-00C04FC964FF", "https://tie.com", title: "tie", done: "2026-03-03"))
        ]}}
        """#)
        #expect(p.reading.list.map(\.title) == ["u1", "u2", "newRead", "tie", "oldRead"])
    }

    @Test func decodeKeepsEveryUnreadItemAboveTheLimit() throws {
        let n = Limits.readingListMax + 5
        let items = (0 ..< n).map { item(UUID().uuidString, "https://u\($0).com", title: "u\($0)") }
        let p = try decode(#"{"reading":{"list":[\#(items.joined(separator: ","))]}}"#)
        #expect(p.reading.list.count == n)
    }

    @Test(arguments: ["file:", "file:foo", "file:///"])
    func addRefusesAnEmptyOrRelativeFileLink(_ text: String) {
        let h = Shelf.harness([])
        #expect(h.engine.addReading(url: text, title: "") == .missingHost)
        #expect(Shelf.list(h).isEmpty)
    }
}
