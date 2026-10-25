import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Reading corner")
struct ReadingCornerTests {
    private func harness(_ style: ReadingReminderStyle) -> EngineHarness {
        EngineHarness {
            $0.prefs.reading.reminderStyle = style
            $0.prefs.general.snoozeMinutes = 5
            $0.prefs.general.ignoreMinutes = 5
        }
    }

    private func snoozedCalls(_ h: EngineHarness) -> [SpyPresenter.Call] {
        h.presenter.calls.filter { if case .showSnoozed = $0 { return true } else { return false } }
    }

    @Test(arguments: [(ReadingReminderStyle.corner, true), (.focus, false)])
    func readingUsesTheCornerOnlyWithTheCornerStyle(_ style: ReadingReminderStyle, _ expected: Bool) {
        #expect(harness(style).engine.usesCorner(.reading) == expected)
    }

    @Test(arguments: [ReadingReminderStyle.corner, .focus])
    func waterAndMeditationNeverUseTheCorner(_ style: ReadingReminderStyle) {
        let h = harness(style)
        #expect(!h.engine.usesCorner(.water))
        #expect(!h.engine.usesCorner(.meditation))
    }

    @Test func snoozingTheCornerPopupShowsTheComesBackNote() {
        let h = harness(.corner)
        h.showReminder(.reading)
        let start = h.clock.now
        h.engine.snooze(.reading)
        let close = h.presenter.calls.lastIndex(of: .closeBubble(.reading))
        let note = h.presenter.calls.firstIndex(of: .showSnoozed(.reading, start.addingTimeInterval(5 * 60)))
        #expect(close != nil)
        #expect(note != nil)
        if let close, let note { #expect(close < note) }
    }

    @Test func ignoringTheCornerPopupShowsTheComesBackNote() {
        let h = harness(.corner)
        h.showReminder(.reading)
        h.advance(minutes: 5)
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.reading).snoozes == 1)
        #expect(snoozedCalls(h).count == 1)
    }

    @Test func snoozingTheFocusBubbleShowsNoNote() {
        let h = harness(.focus)
        h.showReminder(.reading)
        h.engine.snooze(.reading)
        #expect(h.engine.state(.reading).snoozes == 1)
        #expect(snoozedCalls(h).isEmpty)
    }

    @Test(arguments: [ReadingReminderStyle.corner, .focus])
    func snoozingWaterShowsNoNote(_ style: ReadingReminderStyle) {
        let h = harness(style)
        h.showReminder(.water)
        h.engine.snooze(.water)
        #expect(h.engine.state(.water).snoozes == 1)
        #expect(snoozedCalls(h).isEmpty)
    }

    @Test(arguments: [(5, "In 5 min"), (10, "In 10 min")])
    func snoozeShortLabelUsesTheGeneralSnoozeLength(_ minutes: Int, _ expected: String) {
        let h = EngineHarness {
            $0.prefs.reading.reminderStyle = .corner
            $0.prefs.general.snoozeMinutes = minutes
        }
        #expect(h.engine.snoozeShortLabel == expected)
    }

    @Test func comesBackTextNamesTheBuddyAndTheTime() {
        let h = harness(.corner)
        let until = day(2026, 3, 4, 22, 10)
        let text = h.engine.comesBackText(.reading, until: until)
        #expect(text.hasPrefix("Boi comes back at "))
        #expect(text == "Boi comes back at " + until.formatted(date: .omitted, time: .shortened))
    }

    @Test func stoppingACornerSessionFromAReminderEarlySnoozesWithoutADoneEvent() {
        let h = EngineHarness {
            $0.prefs.reading.reminderStyle = .corner
            $0.prefs.reading.sessionMinutes = 15
            $0.prefs.general.snoozeMinutes = 5
        }
        h.showReminder(.reading)
        h.engine.startReading()
        #expect(h.engine.phase(.reading) == .session)
        h.advance(minutes: 5)
        h.engine.stopSession(.reading)
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.reading).snoozes == 1)
        #expect(h.engine.state(.reading).snoozedUntil != nil)
        #expect(!h.engine.data.events.contains { $0.habit == .reading && $0.kind == .done })
        #expect(snoozedCalls(h).isEmpty)
    }
}
