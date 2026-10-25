import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Water bubble")
struct WaterBubbleTests {
    private func bubble(_ h: EngineHarness, _ level: Level = .nudge) -> some View {
        BubbleView(id: .water, level: level).environmentObject(h.engine)
    }

    private func water(_ h: EngineHarness, _ level: Level = .nudge) throws -> InspectableView<ViewType.View<WaterBubble>> {
        try bubble(h, level).inspect().find(WaterBubble.self)
    }

    private func persisting() -> EngineHarness {
        let h = EngineHarness()
        h.showReminder(.water)
        h.engine.snooze(.water)
        h.advance(minutes: 5)
        return h
    }

    @Test func waterUsesTheNewBubble() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        #expect(try bubble(h).inspect().find(WaterBubble.self) != nil)
    }

    @Test func showsEyebrowTitleAndAmountCards() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        let sut = try water(h)
        let time = h.engine.now.formatted(date: .omitted, time: .shortened)
        #expect(try sut.find(text: "WATER · \(time)") != nil)
        #expect(try sut.find(text: h.engine.copy(.water).title) != nil)
        for label in ["A few sips", "Half", "Full glass"] {
            #expect(try sut.find(text: label) != nil)
        }
    }

    @Test func tappingHalfLogsHalfAGlass() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        try Find.button(water(h), holding: "Half").tap()
        #expect(h.engine.data.events.last?.amount == 0.5)
        #expect(h.engine.isCelebrating)
    }

    @Test func snoozeButtonSnoozes() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        try water(h).find(button: "Snooze 5 min").tap()
        #expect(h.engine.activities.isEmpty)
        #expect(h.engine.state(.water).snoozes == 1)
    }

    @Test func persistShowsStillWaitingWarningAndLastSnooze() throws {
        let h = persisting()
        let sut = try water(h, .persist)
        let eyebrow = try sut.find(ViewType.Text.self) { try $0.string().hasPrefix("STILL WAITING · SNOOZED 1× ·") }
        #expect(eyebrow != nil)
        #expect(try sut.find(text: h.engine.warnText(.water)) != nil)
        #expect(try sut.find(button: "Last snooze") != nil)
    }

    @Test func persistShowsTheLockIcon() throws {
        let h = persisting()
        let lock = try water(h, .persist).find(ViewType.Image.self) { try $0.actualImage().name() == "lock.fill" }
        #expect(lock != nil)
    }

    @Test func nudgeHasNoLockIcon() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        let sut = try water(h)
        #expect(throws: (any Error).self) {
            try sut.find(ViewType.Image.self) { try $0.actualImage().name() == "lock.fill" }
        }
    }

    @Test func segmentPicksSipBottle() throws {
        let picked = Box(Container.glass)
        try ContainerSegment(selection: picked.binding).inspect().find(button: "Sip bottle").tap()
        #expect(picked.value == .bottle)
    }

    @Test func segmentMarksTheSelectedContainer() throws {
        let sut = try ContainerSegment(selection: .constant(.bottle)).inspect()
        #expect(try A11y.isSelected(sut.find(button: "Sip bottle")))
        #expect(try !A11y.isSelected(sut.find(button: "Glass")))
    }

    @Test func bottlePrefOpensInBottleMode() throws {
        let h = EngineHarness { $0.prefs.water.container = .bottle }
        h.showReminder(.water)
        let sut = try water(h)
        #expect(try sut.find(text: "Drag the line to where your water is now.") != nil)
        #expect(try sut.find(button: "I refilled it") != nil)
        #expect(Find.lacks(sut, text: "Half"))
    }

    @Test func glassPrefOpensWithAmountCards() throws {
        let h = EngineHarness()
        h.showReminder(.water)
        let sut = try water(h)
        #expect(Find.lacks(sut, text: "I refilled it"))
        #expect(try A11y.isSelected(sut.find(button: "Glass")))
    }
}
