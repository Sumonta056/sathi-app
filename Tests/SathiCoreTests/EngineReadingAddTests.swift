import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reading add")
struct EngineReadingAddTests {
    @Test func limitsMatchTheSpec() {
        #expect(Limits.readingListMax == 50)
        #expect(Limits.readingReadKeep == 50)
        #expect(Limits.readingTitleMax == 120)
        #expect(Limits.readingURLMax == 2048)
    }

    @Test func addKeepsTheLinkTitleAndToday() {
        let h = Shelf.harness([])
        let result = h.engine.addReading(url: "https://example.com/post", title: "A post")
        #expect(result == .added)
        let items = Shelf.list(h)
        #expect(items.count == 1)
        #expect(items.first?.url.absoluteString == "https://example.com/post")
        #expect(items.first?.title == "A post")
        #expect(items.first?.addedOn == Shelf.today)
        #expect(items.first?.doneOn == nil)
    }

    @Test func textIsTrimmedAndTextWithoutSchemeGetsHttps() {
        let h = Shelf.harness([])
        #expect(h.engine.addReading(url: "  example.com/post \n", title: "") == .added)
        #expect(Shelf.urls(h) == ["https://example.com/post"])
    }

    @Test(arguments: ["http://example.com/a", "https://example.com/a", "file:///Users/asha/notes/article.pdf"])
    func acceptedSchemes(_ text: String) {
        let h = Shelf.harness([])
        #expect(h.engine.addReading(url: text, title: "") == .added)
        #expect(Shelf.urls(h) == [text])
    }

    @Test(arguments: ["ftp://example.com/a", "javascript:alert(1)", "mailto:asha@example.com", "data:text/plain,hi"])
    func otherSchemesAreRefused(_ text: String) {
        let h = Shelf.harness([Shelf.unread("a")])
        #expect(h.engine.addReading(url: text, title: "") == .unsupportedScheme)
        #expect(Shelf.urls(h) == ["https://a.com/post"])
    }

    @Test(arguments: ["https://", "http:///path"])
    func webLinkWithoutHostIsRefused(_ text: String) {
        let h = Shelf.harness([Shelf.unread("a")])
        #expect(h.engine.addReading(url: text, title: "") == .missingHost)
        #expect(Shelf.urls(h) == ["https://a.com/post"])
    }

    @Test func emptyTextIsRefused() {
        let h = Shelf.harness([Shelf.unread("a")])
        #expect(h.engine.addReading(url: "   ", title: "Title") != .added)
        #expect(Shelf.urls(h) == ["https://a.com/post"])
    }

    @Test func linkLongerThanTheLimitIsRefused() {
        let h = Shelf.harness([])
        let base = "https://example.com/"
        let tooLong = base + String(repeating: "x", count: 2048 - base.count + 1)
        #expect(h.engine.addReading(url: tooLong, title: "") == .tooLong)
        #expect(Shelf.list(h).isEmpty)
    }

    @Test func linkAtTheLimitIsAccepted() {
        let h = Shelf.harness([])
        let base = "https://example.com/"
        let atLimit = base + String(repeating: "x", count: 2048 - base.count)
        #expect(h.engine.addReading(url: atLimit, title: "") == .added)
        #expect(Shelf.list(h).count == 1)
    }

    @Test func linkAlreadyUnreadIsRefused() {
        let h = Shelf.harness([Shelf.unread("a")])
        #expect(h.engine.addReading(url: "https://a.com/post", title: "Again") == .duplicate)
        #expect(h.engine.addReading(url: "a.com/post", title: "Again") == .duplicate)
        #expect(Shelf.list(h).count == 1)
        #expect(Shelf.list(h).first?.title == "")
    }

    @Test func linkAlreadyReadCanBeAddedAgain() {
        let h = Shelf.harness([Shelf.read("a", on: "2026-03-01")])
        #expect(h.engine.addReading(url: "https://a.com/post", title: "") == .added)
        #expect(Shelf.list(h).count == 2)
        #expect(Shelf.list(h).first?.doneOn == nil)
    }

    @Test func addIsRefusedWhenUnreadItemsAreFull() {
        let full = Shelf.unreadMany(50)
        let h = Shelf.harness(full)
        #expect(h.engine.addReading(url: "https://new.com/post", title: "") == .full)
        #expect(Shelf.list(h) == full)
    }

    @Test func readItemsDoNotCountTowardsTheUnreadLimit() {
        let h = Shelf.harness(Shelf.unreadMany(50 - 1) + Shelf.readMany(50))
        #expect(h.engine.addReading(url: "https://new.com/post", title: "") == .added)
        #expect(Shelf.list(h).filter { $0.doneOn == nil }.count == 50)
    }

    @Test func newItemGoesToTheEndOfTheUnreadItems() {
        let h = Shelf.harness([Shelf.unread("a"), Shelf.unread("b"), Shelf.read("r", on: "2026-03-02")])
        h.engine.addReading(url: "https://c.com/post", title: "")
        #expect(Shelf.urls(h) == ["https://a.com/post", "https://b.com/post", "https://c.com/post", "https://r.com/post"])
    }

    @Test func refusedAddDoesNotSavePrefs() {
        let h = Shelf.harness([Shelf.unread("a")])
        let saves = h.store.prefsSaves
        h.engine.addReading(url: "ftp://a.com", title: "")
        #expect(h.store.prefsSaves == saves)
    }
}
