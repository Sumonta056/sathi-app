import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reading list")
struct EngineReadingListTests {
    private let a = Shelf.unread("a")
    private let b = Shelf.unread("b")
    private let c = Shelf.unread("c")
    private let r1 = Shelf.read("r1", on: "2026-03-02")
    private let r2 = Shelf.read("r2", on: "2026-03-01")

    @Test func markDoneSetsTodayAndMovesToTheTopOfTheReadItems() {
        let h = Shelf.harness([a, b, c, r1, r2])
        h.engine.markReadingDone(id: b.id)
        #expect(Shelf.list(h).map(\.id) == [a.id, c.id, b.id, r1.id, r2.id])
        #expect(Shelf.list(h)[2].doneOn == Shelf.today)
        #expect(Shelf.list(h)[2].title == b.title)
        #expect(Shelf.list(h)[2].url == b.url)
        #expect(Shelf.list(h)[2].addedOn == b.addedOn)
    }

    @Test func markDoneUsesTheDayOfTheClock() {
        let h = Shelf.harness([a], at: day(2026, 3, 9, 23, 30))
        h.engine.markReadingDone(id: a.id)
        #expect(Shelf.list(h).first?.doneOn == Shelf.key("2026-03-09"))
    }

    @Test func markDoneRemovesTheOldestReadItemsAboveTheKeepLimit() {
        let read = Shelf.readMany(50)
        let h = Shelf.harness([a, b] + read)
        h.engine.markReadingDone(id: a.id)
        let readIDs = Shelf.list(h).filter { $0.doneOn != nil }.map(\.id)
        #expect(readIDs.count == 50)
        #expect(readIDs == [a.id] + read.dropLast().map(\.id))
        #expect(Shelf.list(h).first?.id == b.id)
    }

    @Test func markDoneNeverRemovesUnreadItems() {
        let unread = Shelf.unreadMany(50)
        let h = Shelf.harness(unread + Shelf.readMany(50))
        h.engine.markReadingDone(id: unread[0].id)
        #expect(Shelf.list(h).filter { $0.doneOn == nil }.map(\.id) == unread.dropFirst().map(\.id))
        #expect(Shelf.list(h).filter { $0.doneOn != nil }.count == 50)
    }

    @Test func markDoneOfAnUnknownIdChangesNothing() {
        let h = Shelf.harness([a, r1])
        h.engine.markReadingDone(id: UUID())
        #expect(Shelf.list(h) == [a, r1])
    }

    @Test func undoClearsTheDateAndMovesToTheEndOfTheUnreadItems() {
        let h = Shelf.harness([a, b, r1, r2])
        h.engine.undoReadingDone(id: r2.id)
        #expect(Shelf.list(h).map(\.id) == [a.id, b.id, r2.id, r1.id])
        #expect(Shelf.list(h)[2].doneOn == nil)
    }

    @Test func undoAfterMarkDoneBringsTheItemBack() {
        let h = Shelf.harness([a, b])
        h.engine.markReadingDone(id: a.id)
        h.engine.undoReadingDone(id: a.id)
        #expect(Shelf.list(h).map(\.id) == [b.id, a.id])
        #expect(Shelf.list(h).allSatisfy { $0.doneOn == nil })
    }

    @Test func undoIsRefusedWhenUnreadItemsAreFull() {
        let unread = Shelf.unreadMany(50)
        let h = Shelf.harness(unread + [r1])
        h.engine.undoReadingDone(id: r1.id)
        #expect(Shelf.list(h) == unread + [r1])
    }

    @Test func removeDeletesOneItem() {
        let h = Shelf.harness([a, b, r1])
        h.engine.removeReading(id: b.id)
        #expect(Shelf.list(h) == [a, r1])
        h.engine.removeReading(id: r1.id)
        #expect(Shelf.list(h) == [a])
    }

    @Test func removeOfAnUnknownIdChangesNothing() {
        let h = Shelf.harness([a, b])
        let saves = h.store.prefsSaves
        h.engine.removeReading(id: UUID())
        #expect(Shelf.list(h) == [a, b])
        #expect(h.store.prefsSaves == saves)
    }

    @Test func moveChangesThePositionInsideTheUnreadItems() {
        let h = Shelf.harness([a, b, c, r1])
        h.engine.moveReading(id: c.id, to: 0)
        #expect(Shelf.list(h) == [c, a, b, r1])
        h.engine.moveReading(id: c.id, to: 2)
        #expect(Shelf.list(h) == [a, b, c, r1])
        h.engine.moveReading(id: a.id, to: 1)
        #expect(Shelf.list(h) == [b, a, c, r1])
    }

    @Test func moveNeverPutsAnUnreadItemAmongTheReadItems() {
        let h = Shelf.harness([a, b, c, r1, r2])
        h.engine.moveReading(id: a.id, to: 4)
        #expect(Shelf.list(h) == [b, c, a, r1, r2])
    }

    @Test func moveOfAReadItemChangesNothing() {
        let h = Shelf.harness([a, b, r1, r2])
        h.engine.moveReading(id: r2.id, to: 0)
        #expect(Shelf.list(h) == [a, b, r1, r2])
    }
}
