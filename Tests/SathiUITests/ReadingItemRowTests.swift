import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reading list rows")
struct ReadingItemRowTests {
    private let queue = [Books.alpha, Books.beta, Books.gamma, Books.old]

    @Test func moveUpMovesTheItemUpOne() throws {
        let h = Books.harness(queue)
        try Find.button(Books.card(h), label: "Move Beta up").tap()
        #expect(Books.titles(h) == ["Beta", "Alpha", "Gamma", "Old"])
        #expect(h.store.prefs.reading.list.map(\.title) == ["Beta", "Alpha", "Gamma", "Old"])
    }

    @Test func moveDownMovesTheItemDownOne() throws {
        let h = Books.harness(queue)
        try Find.button(Books.card(h), label: "Move Beta down").tap()
        #expect(Books.titles(h) == ["Alpha", "Gamma", "Beta", "Old"])
    }

    @Test func theFirstRowHasNoUpButton() throws {
        let sut = try Books.card(Books.harness(queue))
        #expect(Books.lacksButton(sut, label: "Move Alpha up"))
        #expect(throws: Never.self) { try Find.button(sut, label: "Move Alpha down") }
    }

    @Test func theLastUnreadRowHasNoDownButton() throws {
        let sut = try Books.card(Books.harness(queue))
        #expect(Books.lacksButton(sut, label: "Move Gamma down"))
        #expect(throws: Never.self) { try Find.button(sut, label: "Move Gamma up") }
    }

    @Test func aSingleUnreadRowHasNoMoveButtons() throws {
        let sut = try Books.card(Books.harness([Books.alpha]))
        #expect(Books.lacksButton(sut, label: "Move Alpha up"))
        #expect(Books.lacksButton(sut, label: "Move Alpha down"))
        #expect(throws: Never.self) { try Find.button(sut, label: "Remove Alpha") }
    }

    @Test func removeDeletesThatUnreadItem() throws {
        let h = Books.harness(queue)
        try Find.button(Books.card(h), label: "Remove Beta").tap()
        #expect(h.store.prefs.reading.list.map(\.title) == ["Alpha", "Gamma", "Old"])
    }

    @Test func readRowsHaveNoMoveButtons() throws {
        let sut = try Books.card(Books.harness(queue))
        #expect(throws: Never.self) { try Find.button(sut, label: "Undo Old") }
        #expect(Books.lacksButton(sut, label: "Move Old up"))
        #expect(Books.lacksButton(sut, label: "Move Old down"))
    }

    @Test func undoPutsTheReadItemBackAtTheEndOfUnread() throws {
        let h = Books.harness([Books.alpha, Books.old, Books.older])
        try Find.button(Books.card(h), label: "Undo Old").tap()
        let list = h.store.prefs.reading.list
        #expect(list.map(\.title) == ["Alpha", "Old", "Older"])
        #expect(list[1].doneOn == nil)
    }

    @Test func undoIsDisabledWhenTheUnreadQueueIsFull() throws {
        let many = (0 ..< Limits.readingListMax).map { Books.unread("T\($0)", host: "u\($0).com") }
        let sut = try Books.card(Books.harness(many + [Books.old]))
        #expect(try Find.button(sut, label: "Undo Old").isDisabled())
    }

    @Test func undoIsEnabledWhenTheQueueHasRoom() throws {
        let sut = try Books.card(Books.harness(queue))
        #expect(try !Find.button(sut, label: "Undo Old").isDisabled())
    }

    @Test func removeDeletesThatReadItem() throws {
        let h = Books.harness([Books.alpha, Books.old, Books.older])
        try Find.button(Books.card(h), label: "Remove Old").tap()
        #expect(h.store.prefs.reading.list.map(\.title) == ["Alpha", "Older"])
    }

    @Test func everyButtonNamesItsItem() throws {
        let sut = try Books.card(Books.harness(queue))
        for label in [
            "Remove Alpha",
            "Move Alpha down",
            "Remove Beta",
            "Move Beta up",
            "Move Beta down",
            "Remove Gamma",
            "Move Gamma up",
            "Remove Old",
            "Undo Old"
        ] {
            #expect(throws: Never.self) { try Find.button(sut, label: label) }
        }
    }
}
