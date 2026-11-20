import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker buddy sessions")
struct EngineTrackerSessionTests {
    @Test func aReadingSessionEndsTheRunningActivityAndStartsABuddyActivity() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec")
        h.clock.advance(minutes: 10)
        h.engine.startSession(.reading)
        #expect(h.saved.map(\.text) == ["Spec"])
        #expect(h.saved.first?.end == wed(10, 10))
        #expect(h.running?.kind == .buddy)
        #expect(h.running?.text == "Reading")
        #expect(h.running?.category == "Reading")
        #expect(h.running?.start == wed(10, 10))
        #expect(h.engine.activityCategories.contains(ActivityCategory.buddy(.reading)))
    }

    @Test func breathingAndGymTextsNameThePatternAndTheIdea() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.startSession(.meditation)
        #expect(h.running?.text == "Breathing · Calm 4·6")
        #expect(h.running?.category == "Meditation")
        h.engine.stopSession(.meditation)
        h.engine.startSession(.gym)
        #expect(h.running?.text == "Gym · " + h.engine.gymIdeaText)
        #expect(h.running?.category == "Gym")
    }

    @Test func noPromptAsksWhileASessionRunsAlsoWhenPaused() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.startSession(.meditation)
        h.engine.pauseSession(.meditation)
        h.advance(minutes: 60)
        #expect(h.promptKind == nil)
        #expect(h.trackerShows == [.whatNow])
    }

    @Test func whenTheSessionEndsWhatNowOffersToContinueTheOldActivity() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec")
        h.clock.advance(minutes: 10)
        h.engine.startSession(.reading)
        h.clock.advance(minutes: 5)
        h.engine.stopSession(.reading)
        h.engine.tick()
        #expect(h.promptKind == .whatNow)
        let s = h.engine.trackerPromptState(.whatNow)
        #expect(s?.resume?.text == "Spec")
        #expect(s?.switchTimes == [wed(10, 15)])
        #expect(h.running == nil)
        #expect(h.saved.map(\.kind) == [.work, .buddy])
        #expect(h.saved.last?.end == wed(10, 15))
    }

    @Test func continueStartsTheOldActivityAgainAsANewItemFromTheSessionEnd() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec")
        h.clock.advance(minutes: 10)
        h.engine.startSession(.reading)
        h.clock.advance(minutes: 5)
        h.engine.finishSession(.reading)
        h.engine.tick()
        h.clock.advance(minutes: 2)
        h.engine.continueActivity(switchAt: wed(10, 15))
        #expect(h.running?.text == "Spec")
        #expect(h.running?.start == wed(10, 15))
        #expect(h.running?.id != h.saved.first?.id)
    }

    @Test func skipAfterASessionDoesNotContinueTheOldActivity() {
        let h = EngineHarness.tracker(at: wed(10))
        h.start("Spec")
        h.engine.startSession(.reading)
        h.clock.advance(minutes: 5)
        h.engine.stopSession(.reading)
        h.engine.tick()
        h.engine.skipTrackerPrompt()
        #expect(h.running == nil)
    }

    @Test func aSessionWithNothingRunningBeforeOpensPlainWhatNow() {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.skipTrackerPrompt()
        h.engine.startSession(.reading)
        h.clock.advance(minutes: 20)
        h.engine.stopSession(.reading)
        h.engine.tick()
        #expect(h.promptKind == .whatNow)
        #expect(h.engine.trackerPromptState(.whatNow)?.resume == nil)
    }

    @Test func aWaterGlassMakesNoActivity() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.water.enabled = true }
        h.engine.logWater(1)
        #expect(h.running == nil)
        #expect(h.saved.isEmpty)
    }

    @Test func aQuickReminderMakesNoActivity() {
        let h = EngineHarness.tracker(at: wed(10))
        guard case let .added(id) = h.engine.addQuick(text: "Call", when: .inMinutes(5)) else { return }
        h.advance(minutes: 5)
        h.engine.quickDone(id)
        #expect(h.running == nil)
        #expect(h.saved.isEmpty)
    }

    @Test func aBuddyActivityWritesNoCalendarEvent() {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.defaultCalendarID = "work" }
        h.engine.startSession(.reading)
        h.clock.advance(minutes: 10)
        h.engine.finishSession(.reading)
        #expect(h.saved.first?.kind == .buddy)
        #expect(h.saved.first?.calendarID == nil)
        #expect(h.calendarWriter.saved.isEmpty)
    }

    @Test func aSessionOutsideTrackerHoursMakesNoActivity() {
        let h = EngineHarness.tracker(at: wed(19))
        h.engine.startSession(.reading)
        #expect(h.running == nil)
    }
}
