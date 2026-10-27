import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reading session")
struct EngineReadingSessionTests {
    private let a = Shelf.unread("a")
    private let b = Shelf.unread("b")

    @Test func startReadingOpensThePickAndStartsTheSession() {
        let h = Shelf.harness([a, b])
        h.engine.startReading()
        #expect(h.links.opened == [a.url])
        #expect(h.engine.session(.reading) != nil)
        #expect(h.presenter.calls.contains(.showSession(.reading)))
    }

    @Test func startReadingWithoutAPickOnlyStartsTheSession() {
        let h = Shelf.harness([Shelf.read("r", on: "2026-03-02")])
        h.engine.startReading()
        #expect(h.links.opened.isEmpty)
        #expect(h.engine.session(.reading) != nil)
    }

    @Test func startReadingWithAnEmptyListOpensNothing() {
        let h = Shelf.harness([])
        h.engine.startReading()
        #expect(h.links.opened.isEmpty)
        #expect(h.engine.session(.reading) != nil)
    }

    @Test func theLockPressAndHoldNeverOpensALink() {
        let h = Shelf.harness([a])
        h.engine.lockConfirmed(.reading)
        #expect(h.links.opened.isEmpty)
        #expect(h.engine.session(.reading) != nil)
    }

    @Test func otherSessionStartsNeverOpenALink() {
        let h = EngineHarness {
            $0.prefs.reading.list = [a]
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
        }
        h.engine.startSession(.reading)
        h.engine.startMeditation()
        h.engine.startSession(.gym)
        #expect(h.links.opened.isEmpty)
    }

    @Test func finishReadingWithMarkDoneEndsTheSessionWithFullMinutesAndMarksThePick() {
        let h = Shelf.harness([a, b])
        h.engine.startReading()
        h.advance(minutes: 5)
        h.engine.finishReading(markDone: true)
        #expect(h.engine.session(.reading) == nil)
        #expect(h.history.appended == [.done(.reading, 15, at: day(2026, 3, 4, 10, 5))])
        #expect(Shelf.list(h).map(\.id) == [b.id, a.id])
        #expect(Shelf.list(h)[1].doneOn == Shelf.today)
        #expect(h.engine.readingPick == b)
    }

    @Test func finishReadingWithoutMarkDoneEndsTheSessionAndKeepsThePick() {
        let h = Shelf.harness([a, b])
        h.engine.startReading()
        h.advance(minutes: 5)
        h.engine.finishReading(markDone: false)
        #expect(h.engine.session(.reading) == nil)
        #expect(h.history.appended == [.done(.reading, 15, at: day(2026, 3, 4, 10, 5))])
        #expect(Shelf.list(h) == [a, b])
    }

    @Test func finishReadingInASessionWithoutAPickOnlyFinishesTheSession() {
        let r = Shelf.read("r", on: "2026-03-02")
        let h = Shelf.harness([r])
        h.engine.startReading()
        h.engine.finishReading(markDone: true)
        #expect(h.engine.session(.reading) == nil)
        #expect(h.history.appended == [.done(.reading, 15, at: day(2026, 3, 4, 10))])
        #expect(Shelf.list(h) == [r])
    }

    @Test func finishReadingOutsideASessionOnlyMarksThePickDone() {
        let h = Shelf.harness([a, b])
        let due = h.engine.state(.reading).nextDue
        h.engine.finishReading(markDone: true)
        #expect(Shelf.list(h).map(\.id) == [b.id, a.id])
        #expect(Shelf.list(h)[1].doneOn == Shelf.today)
        #expect(h.history.appended.isEmpty)
        #expect(h.engine.session(.reading) == nil)
        #expect(h.engine.state(.reading).nextDue == due)
        #expect(h.links.opened.isEmpty)
    }

    @Test func finishReadingOutsideASessionWithoutMarkDoneDoesNothing() {
        let h = Shelf.harness([a, b])
        h.engine.finishReading(markDone: false)
        #expect(Shelf.list(h) == [a, b])
        #expect(h.history.appended.isEmpty)
        #expect(h.engine.session(.reading) == nil)
    }
}
