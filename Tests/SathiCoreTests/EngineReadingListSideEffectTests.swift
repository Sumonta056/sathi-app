import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reading list side effects")
struct EngineReadingListSideEffectTests {
    private let a = Shelf.unread("a")
    private let b = Shelf.unread("b")
    private let r = Shelf.read("r", on: "2026-03-02")

    private func changeTheList(_ h: EngineHarness) {
        h.engine.addReading(url: "https://new.com/post", title: "New")
        h.engine.moveReading(id: b.id, to: 0)
        h.engine.markReadingDone(id: a.id)
        h.engine.undoReadingDone(id: r.id)
        h.engine.removeReading(id: b.id)
        h.engine.finishReading(markDone: true)
        #expect(Shelf.urls(h) == ["https://r.com/post", "https://new.com/post", "https://a.com/post"])
    }

    private func snoozedReading() -> EngineHarness {
        let h = EngineHarness(at: day(2026, 3, 4, 21, 59)) {
            $0.prefs.water.enabled = false
            $0.prefs.general.snoozeMinutes = 10
            $0.prefs.reading.list = [a, b, r]
        }
        h.advance(minutes: 1)
        h.engine.snooze(.reading)
        return h
    }

    @Test func eachChangeSavesPrefsAtOnce() {
        let h = Shelf.harness([a, b, r])
        var saves = h.store.prefsSaves
        let steps: [() -> Void] = [
            { h.engine.addReading(url: "https://new.com/post", title: "New") },
            { h.engine.moveReading(id: b.id, to: 0) },
            { h.engine.markReadingDone(id: a.id) },
            { h.engine.undoReadingDone(id: r.id) },
            { h.engine.removeReading(id: b.id) },
            { h.engine.finishReading(markDone: true) }
        ]
        for step in steps {
            step()
            #expect(h.store.prefsSaves == saves + 1)
            #expect(h.store.prefs.reading.list == Shelf.list(h))
            saves = h.store.prefsSaves
        }
    }

    @Test func listChangesKeepTheDueTime() {
        let h = Shelf.harness([a, b, r])
        let due = h.engine.state(.reading).nextDue
        #expect(due == day(2026, 3, 4, 22))
        changeTheList(h)
        #expect(h.engine.state(.reading).nextDue == due)
    }

    @Test func listChangesKeepTheSnooze() {
        let h = snoozedReading()
        let before = h.engine.state(.reading)
        #expect(before.snoozedUntil == day(2026, 3, 4, 22, 10))
        changeTheList(h)
        let after = h.engine.state(.reading)
        #expect(after.snoozedUntil == before.snoozedUntil)
        #expect(after.snoozes == before.snoozes)
        #expect(after.nextDue == before.nextDue)
    }

    @Test func listChangesKeepTheStreakAndWriteNoHistory() {
        let h = EngineHarness(at: day(2026, 3, 4, 10)) {
            $0.prefs.reading.list = [a, b, r]
            $0.events = [1, 2, 3].map { .done(.reading, 15, at: day(2026, 3, $0, 22)) }
        }
        let streak = h.engine.streak(.reading)
        #expect(streak == 3)
        changeTheList(h)
        #expect(h.engine.streak(.reading) == streak)
        #expect(h.history.appended.isEmpty)
    }

    @Test func listChangesShowNoReminderAndOpenNoLink() {
        let h = Shelf.harness([a, b, r])
        let calls = h.presenter.calls
        changeTheList(h)
        #expect(h.presenter.calls == calls)
        #expect(h.links.opened.isEmpty)
    }
}
