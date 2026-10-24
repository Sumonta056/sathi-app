import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Water thanks")
struct WaterThanksTests {
    private func thanks(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try CelebrateView().environmentObject(h.engine).inspect()
    }

    @Test func waterCelebrationUsesTheThanksCard() throws {
        let h = EngineHarness()
        h.engine.logWater(1)
        let sut = try thanks(h)
        #expect(try sut.find(WaterThanks.self) != nil)
        #expect(try sut.find(text: h.engine.celebration.title) != nil)
        #expect(try sut.find(text: "1 of 8 glasses today") != nil)
    }

    @Test func thanksDropsTheOldBadgeAndButton() throws {
        let h = EngineHarness()
        h.engine.logWater(1)
        let sut = try thanks(h)
        #expect(Find.lacks(sut, text: "+1 glass"))
        #expect(Find.lacks(sut, text: "Back to work"))
    }

    @Test func seeYouButtonNamesTheNextReminderAndCloses() throws {
        let h = EngineHarness()
        h.engine.logWater(1)
        #expect(h.engine.waterSeeYou == "See you in 2 hours")
        try thanks(h).find(button: h.engine.waterSeeYou).tap()
        #expect(h.engine.phase == .idle)
    }

    @Test func dropLevelsFollowTheTotal() {
        let levels = (0 ..< 4).map { DropsRow.level($0, total: 2.5) }
        #expect(levels == [.full, .full, .half, .empty])
    }

    @Test(arguments: [0.0, 0.25])
    func firstDropIsEmptyBelowHalf(_ total: Double) {
        #expect(DropsRow.level(0, total: total) == .empty)
    }

    @Test func halfGlassGoalRoundsUpToWholeDrops() throws {
        let h = EngineHarness { $0.prefs.water.dailyGoalGlasses = 7.5 }
        h.engine.logWater(1)
        let row = try thanks(h).find(DropsRow.self).find(ViewType.ForEach.self)
        #expect(row.count == 8)
    }

    @Test(arguments: [(8, 8), (0, 1)])
    func drawsOneDropPerGoalGlass(_ goal: Int, _ drops: Int) throws {
        let row = try DropsRow(total: 0, goal: goal).inspect().find(ViewType.ForEach.self)
        #expect(row.count == drops)
    }

    @Test(arguments: [(5, "No answer in 5 minutes counts as a snooze."), (1, "No answer in 1 minute counts as a snooze.")])
    func ignoreBarExplainsTheAutoSnooze(_ minutes: Int, _ text: String) throws {
        let h = EngineHarness { $0.prefs.general.ignoreMinutes = minutes }
        h.showReminder(.water)
        let sut = IgnoreBar(accent: Night.water, track: Night.border).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: text) != nil)
    }
}
