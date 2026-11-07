import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
func gymReminder(strictness: Strictness = .friendly) -> EngineHarness {
    let h = EngineHarness(at: day(2026, 3, 4, 9)) {
        $0.prefs.gym.enabled = true
        $0.prefs.gym.strictness = strictness
        $0.prefs.water.enabled = false
        $0.prefs.reading.enabled = false
        $0.prefs.general.snoozeMinutes = 5
    }
    h.advance(minutes: 60)
    return h
}

@MainActor
@Suite("Gym invite")
struct GymInviteTests {
    private func invite(_ h: EngineHarness, _ level: Level) throws -> InspectableView<ViewType.ClassifiedView> {
        try GymInvite(level: level).environmentObject(h.engine).inspect()
    }

    @Test func inviteShowsTheIdeaTitleAndTheSessionLine() throws {
        let h = gymReminder()
        h.engine.data.prefs.general.name = "Mira"
        let sut = try invite(h, .nudge)
        #expect(throws: Never.self) { try sut.find(text: "SHOKTI · GYM") }
        #expect(throws: Never.self) { try sut.find(text: "Try neck and shoulder stretch, Mira") }
        #expect(throws: Never.self) { try sut.find(text: "5 minutes. You can do this.") }
        #expect(Find.lacks(sut, text: "Neck and shoulder stretch · 5 min"))
    }

    @Test func theLineUsesTheSessionLength() throws {
        let h = gymReminder()
        h.engine.data.prefs.gym.sessionMinutes = 10
        #expect(throws: Never.self) { try invite(h, .nudge).find(text: "10 minutes. You can do this.") }
    }

    @Test func inviteShowsTheProgressBarForToday() throws {
        let h = gymReminder()
        let sut = try invite(h, .nudge)
        #expect(throws: Never.self) { try sut.find(GymProgressBar.self) }
        #expect(throws: Never.self) { try sut.find(text: "0 of 20 min today · session 1 of 4") }
    }

    @Test func startButtonStartsTheGymSession() throws {
        let h = gymReminder()
        try Find.button(invite(h, .nudge), holding: "Start").tap()
        #expect(h.engine.session(.gym) != nil)
    }

    @Test func nextIdeaIsAnIconButtonThatShowsTheNextIdea() throws {
        let h = gymReminder()
        h.engine.data.prefs.general.name = "Mira"
        let sut = try invite(h, .nudge)
        #expect(Find.lacks(sut, text: "Next idea"))
        try Find.button(sut, label: "Next idea").tap()
        #expect(h.engine.gymIdea == 1)
        #expect(throws: Never.self) { try invite(h, .nudge).find(text: "Try short walk, Mira") }
    }

    @Test func snoozeButtonUsesTheGeneralLabel() throws {
        let h = gymReminder()
        #expect(h.engine.snoozeShortLabel == "In 5 min")
        try Find.button(invite(h, .nudge), holding: h.engine.snoozeShortLabel).tap()
        #expect(h.engine.state(.gym).snoozes == 1)
    }

    @Test func closeButtonIsASnoozeAtNudgeOnly() throws {
        let h = gymReminder()
        let now = h.engine.now
        try Find.button(invite(h, .nudge), label: "Dismiss").tap()
        #expect(h.engine.state(.gym).snoozes == 1)
        #expect(h.engine.state(.gym).snoozedUntil == now.addingTimeInterval(5 * Timing.minute))
        #expect(h.history.appended.last == .snooze(.gym, at: now))

        let p = gymReminder(strictness: .persistent)
        p.engine.snooze(.gym)
        p.advance(minutes: 5)
        #expect(p.engine.phase(.gym) == .bubble(.persist))
        let sut = try invite(p, .persist)
        #expect((try? sut.find(viewWithAccessibilityLabel: "Dismiss")) == nil)
        #expect(try sut.find(text: "Start") != nil)
    }

    @Test func bubbleViewRoutesGymToTheInvite() throws {
        let h = gymReminder()
        let sut = try BubbleView(id: .gym, level: .nudge).environmentObject(h.engine).inspect()
        #expect(try sut.find(GymInvite.self) != nil)
        #expect((try? sut.find(LegacyBubble.self)) == nil)
    }
}
