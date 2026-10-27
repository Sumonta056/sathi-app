import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Reading item title")
struct ReadingItemTitleTests {
    private func item(_ url: String, title: String = "") -> ReadingItem {
        ReadingItem(title: title, url: URL(string: url)!, addedOn: Shelf.today)
    }

    @Test func titleIsTrimmed() {
        let h = Shelf.harness([])
        h.engine.addReading(url: "https://example.com/a", title: "  A good read \n")
        #expect(Shelf.list(h).first?.title == "A good read")
    }

    @Test func longTitleIsCutToTheLimit() {
        let h = Shelf.harness([])
        let long = String(repeating: "a", count: 120 + 30)
        h.engine.addReading(url: "https://example.com/a", title: long)
        #expect(Shelf.list(h).first?.title == String(repeating: "a", count: 120))
    }

    @Test func blankTitleIsStoredEmpty() {
        let h = Shelf.harness([])
        h.engine.addReading(url: "https://www.example.com/a", title: "   ")
        #expect(Shelf.list(h).first?.title == "")
        #expect(Shelf.list(h).first?.displayTitle == "example.com")
    }

    @Test func displayTitleIsTheTitleWhenSet() {
        #expect(item("https://www.example.com/a", title: "Deep work").displayTitle == "Deep work")
    }

    @Test(arguments: [
        ("https://www.example.com/a", "example.com"),
        ("https://blog.example.com/a", "blog.example.com"),
        ("http://news.site.org", "news.site.org"),
        ("https://wwwexample.com/a", "wwwexample.com"),
    ])
    func emptyTitleShowsTheHostWithoutWww(_ url: String, _ expected: String) {
        #expect(item(url).displayTitle == expected)
    }

    @Test func emptyTitleOfAFileShowsTheFileName() {
        #expect(item("file:///Users/asha/notes/article.pdf").displayTitle == "article.pdf")
    }
}

@MainActor
@Suite("Engine reading pick")
struct EngineReadingPickTests {
    @Test func pickIsTheFirstUnreadItem() {
        let a = Shelf.unread("a")
        let h = Shelf.harness([a, Shelf.unread("b"), Shelf.read("r", on: "2026-03-02")])
        #expect(h.engine.readingPick == a)
    }

    @Test func noUnreadItemMeansNoPick() {
        let h = Shelf.harness([Shelf.read("r", on: "2026-03-02")])
        #expect(h.engine.readingPick == nil)
    }

    @Test func emptyListMeansNoPick() {
        #expect(Shelf.harness([]).engine.readingPick == nil)
    }

    @Test func anUnfinishedPickStaysFirstTheNextDay() {
        let a = Shelf.unread("a")
        let h = Shelf.harness([a, Shelf.unread("b")])
        h.advance(minutes: 24 * 60)
        #expect(h.engine.readingPick == a)
    }

    @Test func pickFollowsTheUserOrder() {
        let a = Shelf.unread("a")
        let b = Shelf.unread("b")
        let h = Shelf.harness([a, b])
        h.engine.moveReading(id: b.id, to: 0)
        #expect(h.engine.readingPick == b)
    }
}
