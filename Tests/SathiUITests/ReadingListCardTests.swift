import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reading list card")
struct ReadingListCardTests {
    private let emptyText = "Add a link and Boi will suggest it at reading time."

    @Test func whatToReadSitsRightAfterWhen() throws {
        let sut = try hosted(ReadingSettingsTab(), Books.harness([])).inspect()
        let labels = ["WHEN", "WHAT TO READ", "DAYS OFF", "HOW BOI SAYS HI"]
        let order = Books.texts(sut).filter { labels.contains($0) }
        #expect(order == labels)
        #expect(throws: Never.self) { try sut.find(ReadingListCard.self) }
    }

    @Test func cardHoldsTheAddRow() throws {
        let sut = try Books.card(Books.harness([]))
        #expect(throws: Never.self) { try sut.find(ReadingAddRow.self) }
        #expect(throws: Never.self) { try sut.find(text: "Paste a link") }
    }

    @Test func noItemsShowsTheEmptyLine() throws {
        let sut = try Books.card(Books.harness([]))
        #expect(throws: Never.self) { try sut.find(text: emptyText) }
        #expect(sut.findAll(ReadingItemRow.self).isEmpty)
    }

    @Test func onlyReadItemsStillShowTheEmptyLine() throws {
        let sut = try Books.card(Books.harness([Books.old]))
        #expect(throws: Never.self) { try sut.find(text: emptyText) }
        #expect(Find.lacks(sut, text: "Up next"))
    }

    @Test func unreadItemsHideTheEmptyLine() throws {
        let sut = try Books.card(Books.harness([Books.alpha]))
        #expect(throws: Never.self) { try sut.find(text: "Alpha") }
        #expect(Find.lacks(sut, text: emptyText))
    }

    @Test func unreadRowsAreInQueueOrder() throws {
        let sut = try Books.card(Books.harness([Books.gamma, Books.alpha, Books.beta]))
        let titles = Books.texts(sut).filter { ["Alpha", "Beta", "Gamma"].contains($0) }
        #expect(titles == ["Gamma", "Alpha", "Beta"])
        #expect(sut.findAll(ReadingItemRow.self).count == 3)
    }

    @Test func onlyTheFirstRowIsUpNext() throws {
        let sut = try Books.card(Books.harness([Books.beta, Books.alpha]))
        #expect(Books.texts(sut).filter { $0 == "Up next" }.count == 1)
        let row = try sut.find(text: "Up next").find(ReadingItemRow.self, relation: .parent)
        #expect(throws: Never.self) { try row.find(text: "Beta") }
        #expect(Find.lacks(row, text: "Alpha"))
    }

    @Test func eachRowShowsItsHost() throws {
        let sut = try Books.card(Books.harness([Books.alpha, Books.beta]))
        #expect(throws: Never.self) { try sut.find(text: "alpha.com") }
        #expect(throws: Never.self) { try sut.find(text: "beta.com") }
    }

    @Test func anUntitledRowShowsTheHostWithoutWww() throws {
        let item = try ReadingItem(
            title: "",
            url: #require(URL(string: "https://www.site.com/post")),
            addedOn: #require(DayKey(raw: "2026-03-01"))
        )
        let sut = try Books.card(Books.harness([item]))
        #expect(throws: Never.self) { try sut.find(text: "site.com") }
        #expect(throws: Never.self) { try Find.button(sut, label: "Remove site.com") }
    }

    @Test func anUntitledRowShowsTheHostOnceAndTheLinkWithoutItsScheme() throws {
        let item = try ReadingItem(
            title: "",
            url: #require(URL(string: "https://en.wikipedia.org/wiki/Stoicism")),
            addedOn: #require(DayKey(raw: "2026-03-01"))
        )
        let sut = try Books.card(Books.harness([item]))
        #expect(Books.texts(sut).filter { $0 == "en.wikipedia.org" }.count == 1)
        #expect(throws: Never.self) { try sut.find(text: "en.wikipedia.org/wiki/Stoicism") }
    }

    @Test func aFileRowShowsTheFileName() throws {
        let item = try ReadingItem(title: "Notes", url: URL(fileURLWithPath: "/Users/me/notes.pdf"), addedOn: #require(DayKey(raw: "2026-03-01")))
        let sut = try Books.card(Books.harness([item]))
        #expect(throws: Never.self) { try sut.find(text: "Notes") }
        #expect(throws: Never.self) { try sut.find(text: "notes.pdf") }
    }

    @Test func noReadItemsShowsNoReadLabel() throws {
        let sut = try Books.card(Books.harness([Books.alpha]))
        #expect(throws: Never.self) { try sut.find(text: "Alpha") }
        #expect(!Books.texts(sut).contains { $0.hasPrefix("READ") })
    }

    @Test func readItemsShowTheReadLabelWithTheCount() throws {
        let sut = try Books.card(Books.harness([Books.alpha, Books.old, Books.older]))
        #expect(throws: Never.self) { try sut.find(text: "READ · 2") }
        let all = Books.texts(sut)
        let label = try #require(all.firstIndex(of: "READ · 2"))
        #expect(try #require(all.firstIndex(of: "Alpha")) < label)
        #expect(try label < #require(all.firstIndex(of: "Old")))
    }

    @Test func readRowsShowTitleAndDoneDate() throws {
        let sut = try Books.card(Books.harness([Books.old, Books.older]))
        #expect(throws: Never.self) { try sut.find(text: "Old") }
        #expect(throws: Never.self) { try sut.find(text: "Read Mar 3") }
        #expect(throws: Never.self) { try sut.find(text: "Read Mar 1") }
        #expect(Books.texts(sut).filter { $0 == "Undo" }.count == 2)
    }
}
