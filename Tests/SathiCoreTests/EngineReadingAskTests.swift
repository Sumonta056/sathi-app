import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine reading ask")
struct EngineReadingAskTests {
    private let a = Shelf.unread("a")
    private let b = Shelf.unread("b")

    private func timedOut(_ list: [ReadingItem]) -> EngineHarness {
        let h = EngineHarness {
            $0.prefs.reading.list = list
            $0.prefs.reading.sessionMinutes = 15
        }
        h.engine.startReading()
        h.advance(minutes: 16)
        return h
    }

    @Test func aTimedOutSessionWithAPickAsksAboutThePick() {
        let h = timedOut([a, b])
        #expect(h.engine.isCelebrating)
        #expect(h.engine.celebration.id == .reading)
        #expect(h.engine.celebration.readingAsk == a.id)
    }

    @Test func aTimedOutSessionKeepsThePickUnread() {
        let h = timedOut([a, b])
        #expect(Shelf.list(h) == [a, b])
    }

    @Test func aTimedOutSessionWithoutAPickDoesNotAsk() {
        let h = timedOut([Shelf.read("r", on: "2026-03-02")])
        #expect(h.engine.isCelebrating)
        #expect(h.engine.celebration.readingAsk == nil)
    }

    @Test func aTimedOutSessionWithAnEmptyListDoesNotAsk() {
        let h = timedOut([])
        #expect(h.engine.isCelebrating)
        #expect(h.engine.celebration.readingAsk == nil)
    }

    @Test(arguments: [true, false])
    func finishingReadingByHandDoesNotAsk(_ markDone: Bool) {
        let h = Shelf.harness([a, b])
        h.engine.startReading()
        h.advance(minutes: 5)
        h.engine.finishReading(markDone: markDone)
        #expect(h.engine.isCelebrating)
        #expect(h.engine.celebration.readingAsk == nil)
    }

    @Test func otherHabitsNeverAsk() {
        let h = EngineHarness {
            $0.prefs.reading.list = [a]
            $0.prefs.meditation.enabled = true
        }
        h.engine.startMeditation()
        h.advance(minutes: 3)
        #expect(h.engine.celebration.id == .meditation)
        #expect(h.engine.celebration.readingAsk == nil)
        h.engine.logWater(1)
        #expect(h.engine.celebration.id == .water)
        #expect(h.engine.celebration.readingAsk == nil)
    }

    @Test func aLaterCelebrationClearsTheAsk() {
        let h = timedOut([a])
        h.engine.endCelebrate()
        h.engine.logWater(1)
        #expect(h.engine.celebration.readingAsk == nil)
    }

    @Test func theAskLastsTwentySeconds() {
        #expect(Timing.readingAskDuration == 20)
        #expect(Timing.celebrationDuration == 4.5)
    }

    @Test func whileItAsksTheCelebrationStaysForTheAskDuration() {
        let h = timedOut([a])
        #expect(h.engine.celebrationDuration == 20)
    }

    @Test func withoutAnAskTheCelebrationStaysTheUsualTime() {
        let h = timedOut([])
        #expect(h.engine.celebrationDuration == Timing.celebrationDuration)
    }

    @Test func aHandFinishedReadingStaysTheUsualTime() {
        let h = Shelf.harness([a])
        h.engine.startReading()
        h.engine.finishReading(markDone: false)
        #expect(h.engine.celebrationDuration == Timing.celebrationDuration)
    }

    @Test func theAskNamesTheItemTheSessionOpenedEvenWhenAnotherMovesToTheTop() {
        let h = Shelf.harness([a, b])
        h.engine.startReading()
        h.engine.moveReading(id: b.id, to: 0)
        h.advance(minutes: 16)
        #expect(h.engine.celebration.readingAsk == a.id)
    }

    @Test func finishedItMarksTheOpenedItemEvenWhenAnotherMovesToTheTop() {
        let h = Shelf.harness([a, b])
        h.engine.startReading()
        h.engine.moveReading(id: b.id, to: 0)
        h.engine.finishReading(markDone: true)
        let list = Shelf.list(h)
        #expect(list.first { $0.id == a.id }?.doneOn != nil)
        #expect(list.first { $0.id == b.id }?.doneOn == nil)
    }

    @Test func noAskWhenTheOpenedItemIsMarkedDoneMidSession() {
        let h = Shelf.harness([a, b])
        h.engine.startReading()
        h.engine.markReadingDone(id: a.id)
        h.advance(minutes: 16)
        #expect(h.engine.isCelebrating)
        #expect(h.engine.celebration.readingAsk == nil)
    }

    @Test func noAskWhenALinkIsAddedToAnEmptyListMidSession() {
        let h = Shelf.harness([])
        h.engine.startReading()
        h.engine.addReading(url: "https://new.com/post", title: "New")
        h.advance(minutes: 16)
        #expect(h.engine.celebration.readingAsk == nil)
        #expect(h.engine.readingSessionItem == nil)
    }

    @Test func aLockStartedSessionNeverAsks() {
        let h = Shelf.harness([a])
        h.engine.startSession(.reading)
        h.advance(minutes: 16)
        #expect(h.engine.isCelebrating)
        #expect(h.engine.celebration.readingAsk == nil)
        #expect(h.links.opened.isEmpty)
    }

    @Test func noAskWithTheFocusStyle() {
        let h = EngineHarness {
            $0.prefs.reading.list = [a]
            $0.prefs.reading.reminderStyle = .focus
            $0.prefs.reading.sessionMinutes = 15
        }
        h.engine.startReading()
        h.advance(minutes: 16)
        #expect(h.engine.celebration.readingAsk == nil)
        #expect(h.engine.celebrationDuration == Timing.celebrationDuration)
    }

    @Test func aWaterLogDuringTheAskReplacesItAndLeavesTheList() {
        let h = timedOut([a, b])
        #expect(h.engine.celebration.readingAsk == a.id)
        h.engine.logWater(1)
        #expect(h.engine.celebration.id == .water)
        #expect(h.engine.celebration.readingAsk == nil)
        #expect(Shelf.list(h) == [a, b])
    }
}
