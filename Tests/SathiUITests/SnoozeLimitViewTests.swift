import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
func noSnoozeLeft(_ s: ReminderSurface, limit: Int = 1) -> EngineHarness {
    let h = s.harness {
        $0.prefs.general.snoozeLimit = limit
        $0.prefs.water.strictness = .friendly
        $0.prefs.reading.strictness = .friendly
        $0.prefs.meditation.strictness = .friendly
        $0.prefs.gym.strictness = .friendly
    }
    for _ in 0 ..< limit {
        h.engine.snooze(s.id)
        h.advance(minutes: 5)
    }
    return h
}

@MainActor
func hasText(_ sut: InspectableView<some BaseViewType>, containing part: String) -> Bool {
    sut.findAll(ViewType.Text.self).contains { ((try? $0.string()) ?? "").contains(part) }
}

@MainActor
@Suite("Snooze limit views")
struct SnoozeLimitViewTests {
    private let snoozeTitles = ["Snooze 5 min", "Last snooze", "In 5 min"]

    @Test(arguments: ReminderSurface.allCases)
    func noSnoozeLeftHidesSnoozeAndClose(_ s: ReminderSurface) throws {
        let h = noSnoozeLeft(s)
        #expect(h.engine.phase(s.id) == .bubble(.nudge))
        #expect(!h.engine.canSnooze(s.id))
        let sut = try s.inspect(h, .nudge)
        for title in snoozeTitles {
            #expect(Find.lacks(sut, text: title))
        }
        #expect(!hasDismiss(sut))
        #expect(!hasText(sut, containing: "counts as a snooze"))
    }

    @Test(arguments: ReminderSurface.allCases)
    func noSnoozeLeftShowsSkipToday(_ s: ReminderSurface) throws {
        let h = noSnoozeLeft(s)
        #expect(throws: Never.self) { try s.inspect(h, .nudge).find(button: "Skip today") }
    }

    @Test(arguments: ReminderSurface.allCases)
    func withSnoozesLeftTheReminderHasNoSkipToday(_ s: ReminderSurface) throws {
        let h = s.harness { $0.prefs.general.snoozeLimit = 3 }
        let sut = try s.inspect(h, .nudge)
        #expect(Find.lacks(sut, text: "Skip today"))
        #expect(hasDismiss(sut))
    }

    @Test func waterEyebrowSaysNoSnoozesLeft() throws {
        let h = noSnoozeLeft(.waterBubble)
        #expect(throws: Never.self) {
            try ReminderSurface.waterBubble.inspect(h, .nudge).find(text: "NO SNOOZES LEFT · 1 OF 1 USED")
        }
    }

    @Test func waterBubbleWithOneSnoozeLeftSaysLastSnooze() throws {
        let h = ReminderSurface.waterBubble.harness {
            $0.prefs.general.snoozeLimit = 1
            $0.prefs.water.strictness = .friendly
        }
        #expect(h.engine.canSnooze(.water))
        #expect(throws: Never.self) { try ReminderSurface.waterBubble.inspect(h, .nudge).find(button: "Last snooze") }
    }

    @Test func skipTodayButtonStartsWithOneButton() throws {
        let h = noSnoozeLeft(.waterBubble)
        let sut = try SkipTodayButton(id: .water).environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(button: "Skip today") }
        #expect(Find.lacks(sut, text: "Skip anyway"))
    }

    @Test func confirmingNamesTheStreakAndOffersBothChoices() throws {
        let h = streakHarness()
        #expect(h.engine.streak(.water) == 3)
        let sut = try SkipTodayButton(id: .water, confirming: true).environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Skipping resets your 3-day streak to zero.") }
        #expect(throws: Never.self) { try sut.find(button: "Keep my streak") }
        #expect(throws: Never.self) { try sut.find(button: "Skip anyway") }
    }

    @Test func skipAnywayIsTheEmergencySkip() throws {
        let h = streakHarness()
        try SkipTodayButton(id: .water, confirming: true).environmentObject(h.engine).inspect().find(button: "Skip anyway").tap()
        #expect(h.engine.activities[.water] == nil)
        #expect(h.history.appended.last == .skip(.water, at: h.clock.now))
        #expect(h.engine.streak(.water) == 0)
    }

    @Test func keepMyStreakSkipsNothing() throws {
        let h = streakHarness()
        try SkipTodayButton(id: .water, confirming: true).environmentObject(h.engine).inspect().find(button: "Keep my streak").tap()
        #expect(h.engine.phase(.water) == .bubble(.nudge))
        #expect(!h.history.appended.contains { $0.kind == .skip })
    }

    private func streakHarness() -> EngineHarness {
        let h = EngineHarness {
            $0.prefs.general.snoozeLimit = 1
            $0.prefs.water.strictness = .friendly
            $0.events = (0 ..< 3).map { .done(.water, 8, at: Calendar.current.date(byAdding: .day, value: -$0, to: day(2026, 3, 3, 12))!) }
        }
        h.showReminder(.water)
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        return h
    }

    @Test func warningNamesTheStreakOrAMissedDay() {
        #expect(SkipTodayButton.warning(streak: 3) == "Skipping resets your 3-day streak to zero.")
        #expect(SkipTodayButton.warning(streak: 0) == "Skipping counts today as missed.")
    }
}
