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

    @Test func inviteShowsLabelAndWorkoutHint() throws {
        let h = gymReminder()
        let sut = try invite(h, .nudge)
        #expect(try sut.find(text: "SHOKTI · GYM") != nil)
        #expect(try sut.find(text: h.engine.copy(.gym).title) != nil)
        #expect(try sut.find(text: "Neck and shoulder stretch · 5 min") != nil)
    }

    @Test func startButtonStartsTheGymSession() throws {
        let h = gymReminder()
        try Find.button(invite(h, .nudge), holding: "Start").tap()
        #expect(h.engine.session(.gym) != nil)
    }

    @Test func nextIdeaButtonCallsNextGymIdea() throws {
        let h = gymReminder()
        try Find.button(invite(h, .nudge), holding: "Next idea").tap()
        #expect(h.engine.gymIdea == 1)
    }

    @Test func snoozeButtonUsesTheGeneralLabel() throws {
        let h = gymReminder()
        #expect(h.engine.snoozeShortLabel == "In 5 min")
        try Find.button(invite(h, .nudge), holding: h.engine.snoozeShortLabel).tap()
        #expect(h.engine.state(.gym).snoozes == 1)
    }

    @Test func closeButtonIsNotNowAtNudgeOnly() throws {
        let h = gymReminder()
        let now = h.engine.now
        try Find.button(invite(h, .nudge), label: "Dismiss").tap()
        #expect(h.engine.state(.gym).nextDue == now.addingTimeInterval(60 * Timing.minute))
        #expect(h.engine.state(.gym).snoozes == 0)

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
