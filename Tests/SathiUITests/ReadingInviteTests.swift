import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reading invite")
struct ReadingInviteTests {
    private func harness() -> EngineHarness {
        EngineHarness {
            $0.prefs.reading.reminderStyle = .corner
            $0.prefs.reading.sessionMinutes = 15
            $0.prefs.reading.strictness = .persistent
            $0.prefs.general.snoozeMinutes = 5
        }
    }

    private func invite(_ h: EngineHarness, _ level: Level) throws -> InspectableView<ViewType.ClassifiedView> {
        try ReadingInvite(level: level).environmentObject(h.engine).inspect()
    }

    @Test func nudgeShowsTheInviteCopyAndButtons() throws {
        let h = harness()
        h.showReminder(.reading)
        let sut = try invite(h, .nudge)
        #expect(try sut.find(text: "BOI · READING") != nil)
        #expect(try sut.find(text: h.engine.copy(.reading).title) != nil)
        #expect(try sut.find(text: "15 calm minutes with your book.") != nil)
        #expect(try sut.find(text: "Start reading") != nil)
        #expect(try sut.find(text: "In 5 min") != nil)
        #expect(try Find.button(sut, label: "Dismiss") != nil)
    }

    @Test func startReadingStartsTheSession() throws {
        let h = harness()
        h.showReminder(.reading)
        try Find.button(invite(h, .nudge), holding: "Start reading").tap()
        #expect(h.engine.phase(.reading) == .session)
    }

    @Test func snoozeButtonSnoozes() throws {
        let h = harness()
        h.showReminder(.reading)
        try Find.button(invite(h, .nudge), holding: "In 5 min").tap()
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.reading).snoozes == 1)
    }

    @Test func dismissSnoozes() throws {
        let h = harness()
        h.showReminder(.reading)
        try Find.button(invite(h, .nudge), label: "Dismiss").tap()
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.reading).snoozes == 1)
    }

    @Test func persistHasNoDismissAndShowsTheWarning() throws {
        let h = harness()
        h.showReminder(.reading)
        h.engine.snooze(.reading)
        h.advance(minutes: 5)
        #expect(h.engine.phase(.reading) == .bubble(.persist))
        let sut = try invite(h, .persist)
        #expect((try? sut.find(viewWithAccessibilityLabel: "Dismiss")) == nil)
        #expect(try sut.find(text: h.engine.warnText(.reading)) != nil)
        #expect(try sut.find(text: "Start reading") != nil)
    }

    @Test(arguments: [ReadingReminderStyle.corner, .focus])
    func bubbleViewKeepsTheLegacyBubbleForReading(_ style: ReadingReminderStyle) throws {
        let h = EngineHarness { $0.prefs.reading.reminderStyle = style }
        h.showReminder(.reading)
        let sut = try BubbleView(id: .reading, level: .nudge).environmentObject(h.engine).inspect()
        #expect(try sut.find(LegacyBubble.self) != nil)
        #expect((try? sut.find(ReadingInvite.self)) == nil)
    }
}
