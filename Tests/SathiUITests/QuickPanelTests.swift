import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick panel")
struct QuickPanelTests {
    private func panel(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(MenuPanel(), h).inspect()
    }

    private func trackerHarness(running: Bool = false) -> EngineHarness {
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 10)) {
            $0.prefs.water.enabled = true
            $0.prefs.reading.enabled = true
        }
        if running { h.engine.startActivity(ActivityDraft(text: "Code review", length: .minutes(30))) }
        return h
    }

    @Test func headerShowsTheNameAndTheShortClock() throws {
        let sut = try panel(Glance.harness())
        #expect(throws: Never.self) { try sut.find(text: "Sathi") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.quickPanelClock(Quick.now, calendar: .current)) }
    }

    @Test func runningActivityShowsNowRowWithSwitch() throws {
        let h = trackerHarness(running: true)
        let sut = try panel(h)
        #expect(throws: Never.self) { try sut.find(text: "Code review") }
        #expect(MenuFind.hasText(sut, containing: "NOW · "))
        try sut.find(viewWithAccessibilityIdentifier: "quick.switch").button().tap()
        #expect(h.engine.trackerPrompt?.kind == .center)
    }

    @Test func idleTrackerShowsNotTrackingWithLogActivity() throws {
        let h = trackerHarness()
        let sut = try panel(h)
        #expect(throws: Never.self) { try sut.find(text: "Not tracking now") }
        try sut.find(viewWithAccessibilityIdentifier: "quick.log").button().tap()
        #expect(h.engine.trackerPrompt?.kind == .center)
    }

    @Test func trackerOffShowsNoNowRow() throws {
        let sut = try panel(Glance.harness())
        #expect(Find.lacks(sut, text: "Not tracking now"))
        #expect(Find.lacks(sut, text: "Log activity"))
    }

    @Test func fourBuddyRowsShowNameAndStatus() throws {
        let h = Glance.harness()
        h.engine.logWater(5)
        let sut = try panel(h)
        let rows = sut.findAll(QuickBuddyRow.self)
        #expect(try rows.map { try $0.actualView().buddy.habit } == HabitID.allCases)
        for name in ["Fota", "Boi", "Shanti", "Shokti"] {
            #expect(throws: Never.self) { try sut.find(text: name) }
        }
        #expect(throws: Never.self) { try sut.find(text: "5 / 8") }
    }

    @Test func offBuddyShowsOff() throws {
        let h = EngineHarness(at: Quick.now) { $0.prefs.gym.enabled = false }
        #expect(try panel(h).findAll(QuickBuddyRow.self).count == 4)
        #expect(throws: Never.self) { try panel(h).find(text: "Off") }
    }

    @Test func metBuddyShowsGoalMet() throws {
        let h = Glance.harness()
        h.engine.logWater(8)
        #expect(throws: Never.self) { try panel(h).find(text: "✓ Goal met") }
    }

    @Test func plusOneGlassLogsAGlass() throws {
        let h = Glance.harness()
        let before = h.engine.glassesToday
        try panel(h).find(viewWithAccessibilityIdentifier: "quick.glass").button().tap()
        #expect(h.engine.glassesToday == before + 1)
    }

    @Test func onlyFotaHasAQuickAction() throws {
        let sut = try panel(Glance.harness())
        #expect(sut.findAll(where: { (try? $0.text().string()) == "+1 glass" }).count == 1)
    }

    @Test func openSathiOpensToday() throws {
        let h = Glance.harness()
        try panel(h).find(viewWithAccessibilityIdentifier: "quick.openSathi").button().tap()
        #expect(h.presenter.calls.last == .showMain(.today))
    }

    @Test func reportsLinkOpensReports() throws {
        let h = Glance.harness()
        try panel(h).find(viewWithAccessibilityIdentifier: "quick.reports").button().tap()
        #expect(h.presenter.calls.last == .showMain(.reports))
    }

    @Test func settingsLinkOpensGeneralSettings() throws {
        let h = Glance.harness()
        try panel(h).find(viewWithAccessibilityIdentifier: "quick.settings").button().tap()
        #expect(h.presenter.calls.last == .showMain(.settings(.general)))
    }

    @Test func quitIsThere() throws {
        #expect(throws: Never.self) { try panel(Glance.harness()).find(viewWithAccessibilityIdentifier: "quick.quit") }
    }

    @Test func quickReminderButtonOpensTheAddPopup() throws {
        let h = Glance.harness()
        try panel(h).find(viewWithAccessibilityIdentifier: "quick.reminder").button().tap()
        #expect(h.presenter.calls.last == .showQuickAdd)
    }

    @Test func timeBlockButtonOpensTheStartPopup() throws {
        let h = Glance.harness()
        try panel(h).find(viewWithAccessibilityIdentifier: "quick.timeBlock").button().tap()
        #expect(h.presenter.calls.last == .showBlockStart)
    }

    @Test func timeBlockCardShowsOnlyWhileABlockRuns() throws {
        let idle = try panel(Glance.harness())
        #expect(Find.lacks(idle, text: "End now"))
        #expect(throws: Never.self) { try idle.find(viewWithAccessibilityIdentifier: "quick.timeBlock") }
        let running = try panel(Glance.harness(block: .minutes(30)))
        #expect(throws: Never.self) { try running.find(button: "End now") }
        #expect((try? running.find(viewWithAccessibilityIdentifier: "quick.timeBlock")) == nil)
    }

    @Test func breakMenuIsInTheActionRow() throws {
        let sut = try panel(Glance.harness())
        #expect(sut.findAll(BreakMenu.self).count == 1)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "quick.break") }
        #expect(throws: Never.self) { try sut.find(text: "Quick reminder") }
    }

    @Test func pausedPanelShowsTheNapBannerAndWakeUp() throws {
        let h = Glance.harness()
        h.engine.pause(hours: 1)
        let sut = try panel(h)
        #expect(sut.findAll(NapBanner.self).count == 1)
        try MenuFind.control(sut, "Wake up").tap()
        #expect(h.engine.pausedUntil == nil)
    }

    @Test func noBannerWithoutAPause() throws {
        #expect(try panel(Glance.harness()).findAll(NapBanner.self).isEmpty)
    }

    @Test func panelHoldsNoOldCardsOrAddForm() throws {
        let sut = try panel(Glance.harness(reminders: 2))
        #expect(sut.findAll(QuickAddForm.self).isEmpty)
    }

    @Test func widthIsTheMockupWidth() {
        #expect(UIMetrics.quickPanelWidth == 360)
    }
}
