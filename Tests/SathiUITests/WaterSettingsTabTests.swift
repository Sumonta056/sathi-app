import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Water settings tab")
struct WaterSettingsTabTests {
    private let intervalChips = ["30 min", "60 min", "90 min", "120 min"]

    private func tab(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(WaterSettingsTab(), h).inspect()
    }

    @Test func intervalChipsAreTheFourChoices() {
        #expect(Limits.waterIntervalChips == [30, 60, 90, 120])
    }

    @Test func chipSetsTheInterval() throws {
        let h = EngineHarness()
        try tab(h).find(button: "60 min").tap()
        #expect(h.engine.data.prefs.water.intervalMinutes == 60)
    }

    @Test func savedIntervalChipIsSelected() throws {
        let sut = try tab(EngineHarness())
        #expect(try A11y.isSelected(sut.find(button: "120 min")))
        #expect(try !A11y.isSelected(sut.find(button: "60 min")))
    }

    @Test func savedIntervalOutsideTheChipsSelectsNoChip() throws {
        let sut = try tab(EngineHarness { $0.prefs.water.intervalMinutes = 45 })
        for title in intervalChips {
            #expect(try !A11y.isSelected(sut.find(button: title)))
        }
    }

    @Test func moreGlassesRaisesTheGoalByOne() throws {
        let h = EngineHarness { $0.prefs.water.dailyGoalGlasses = 8 }
        try Find.button(tab(h), label: "More glasses").tap()
        #expect(h.engine.data.prefs.water.dailyGoalGlasses == 9)
    }

    @Test func fewerGlassesLowersTheGoalByOne() throws {
        let h = EngineHarness { $0.prefs.water.dailyGoalGlasses = 8 }
        try Find.button(tab(h), label: "Fewer glasses").tap()
        #expect(h.engine.data.prefs.water.dailyGoalGlasses == 7)
    }

    @Test func goalNeverGoesOverTheUpperBound() throws {
        let top = Limits.dailyGoalGlasses.upperBound
        let h = EngineHarness { $0.prefs.water.dailyGoalGlasses = top }
        let more = try Find.button(tab(h), label: "More glasses")
        try? more.tap()
        #expect(h.engine.data.prefs.water.dailyGoalGlasses == top)
    }

    @Test func goalNeverGoesUnderTheLowerBound() throws {
        let bottom = Limits.dailyGoalGlasses.lowerBound
        let h = EngineHarness { $0.prefs.water.dailyGoalGlasses = bottom }
        let fewer = try Find.button(tab(h), label: "Fewer glasses")
        try? fewer.tap()
        #expect(h.engine.data.prefs.water.dailyGoalGlasses == bottom)
    }

    @Test func goalNumberIsShown() throws {
        let sut = try tab(EngineHarness { $0.prefs.water.dailyGoalGlasses = 11 })
        #expect(throws: Never.self) { try sut.find(text: "11") }
        #expect(throws: Never.self) { try sut.find(text: "glasses") }
    }

    @Test func strictCardSetsStrict() throws {
        let h = EngineHarness { $0.prefs.water.strictness = .friendly }
        try Find.button(tab(h), holding: "Strict").tap()
        #expect(h.engine.data.prefs.water.strictness == .strict)
    }

    @Test func ignoreCardsShowAllThreeLevelsWithDetails() throws {
        let sut = try tab(EngineHarness())
        for s in Strictness.allCases {
            #expect(throws: Never.self) { try sut.find(text: s.title) }
            #expect(throws: Never.self) { try sut.find(text: s.detail) }
        }
        #expect(try A11y.isSelected(Find.button(sut, holding: "Strict")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Gentle")))
    }

    @Test func bottleRowShowsOnlyForTheBottle() throws {
        #expect(try Find.lacks(tab(EngineHarness { $0.prefs.water.container = .glass }), text: "My bottle holds"))
        let bottle = try tab(EngineHarness { $0.prefs.water.container = .bottle })
        #expect(throws: Never.self) { try bottle.find(text: "My bottle holds") }
        #expect(throws: Never.self) { try bottle.find(text: "3 glasses") }
    }

    @Test func sipBottleChipSetsTheContainer() throws {
        let h = EngineHarness()
        try tab(h).find(button: "Sip bottle").tap()
        #expect(h.engine.data.prefs.water.container == .bottle)
    }

    @Test func heroSwitchTurnsWaterOff() throws {
        let h = EngineHarness()
        try Find.button(tab(h), label: "Water reminders").tap()
        #expect(!h.engine.data.prefs.water.enabled)
    }

    @Test func sectionsAreDisabledWhileWaterIsOff() throws {
        let sut = try tab(EngineHarness { $0.prefs.water.enabled = false })
        #expect(try sut.find(button: "60 min").isDisabled())
        #expect(try Find.button(sut, holding: "Gentle").isDisabled())
        #expect(try !Find.button(sut, label: "Water reminders").isDisabled())
    }
}
