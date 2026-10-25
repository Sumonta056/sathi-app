import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Meditation invite")
struct MeditationInviteTests {
    private func harness(_ strictness: Strictness = .friendly) -> EngineHarness {
        let start = day(2026, 3, 4, 15)
        let h = EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.prefs.meditation.sessionMinutes = 5
            $0.prefs.meditation.style = .box
            $0.prefs.meditation.strictness = strictness
            $0.prefs.general.snoozeMinutes = 5
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
        }
        h.showReminder(.meditation)
        return h
    }

    private func bubble(_ h: EngineHarness, _ level: Level = .nudge) throws -> InspectableView<ViewType.ClassifiedView> {
        try BubbleView(id: .meditation, level: level).environmentObject(h.engine).inspect()
    }

    @Test func bubbleShowsTheInvite() throws {
        let h = harness()
        #expect(h.engine.phase(.meditation) == .bubble(.nudge))
        let sut = try bubble(h)
        #expect(try sut.find(MeditationInvite.self) != nil)
        #expect((try? sut.find(LegacyBubble.self)) == nil)
        #expect(try sut.find(text: "SHANTI · MEDITATION") != nil)
        #expect(try sut.find(text: h.engine.copy(.meditation).title) != nil)
        #expect(try sut.find(text: "5 minutes of box breathing. Shanti counts for you.") != nil)
        #expect(try sut.find(text: "Breathe with me") != nil)
        #expect(try sut.find(text: "In 5 min") != nil)
        #expect(Find.lacks(sut, text: "Later"))
    }

    @Test func snoozeLabelFollowsTheGeneralSnoozeLength() throws {
        let start = day(2026, 3, 4, 15)
        let h = EngineHarness(at: start) {
            $0.prefs.meditation.enabled = true
            $0.prefs.general.snoozeMinutes = 10
            $0.live.lastWaterDone = start.addingTimeInterval(-Timing.minute)
        }
        #expect(try bubble(h).find(text: "In 10 min") != nil)
    }

    @Test func breatheWithMeStartsTheSession() throws {
        let h = harness()
        try Find.button(bubble(h), holding: "Breathe with me").tap()
        #expect(h.engine.phase(.meditation) == .session)
    }

    @Test func snoozeButtonSnoozes() throws {
        let h = harness()
        try Find.button(bubble(h), holding: "In 5 min").tap()
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.meditation).snoozes == 1)
    }

    @Test func persistShowsTheWarning() throws {
        let h = harness(.persistent)
        h.engine.snooze(.meditation)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.meditation) == .bubble(.persist))
        let sut = try MeditationInvite(level: .persist).environmentObject(h.engine).inspect()
        #expect(try sut.find(text: h.engine.warnText(.meditation)) != nil)
        #expect(try sut.find(text: "Breathe with me") != nil)
    }

    @Test func nudgeHidesTheWarning() throws {
        let h = harness(.persistent)
        let sut = try MeditationInvite(level: .nudge).environmentObject(h.engine).inspect()
        #expect(try sut.find(text: "Breathe with me") != nil)
        #expect(Find.lacks(sut, text: h.engine.warnText(.meditation)))
    }
}
