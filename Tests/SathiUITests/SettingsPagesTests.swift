import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Settings pages")
struct SettingsPagesTests {
    private func page(_ page: SettingsPage, _ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(SettingsPageView(page: page), h).inspect()
    }

    @Test(arguments: SettingsPage.all)
    func everyPageShowsItsEyebrowTitleAndFooter(_ p: SettingsPage) throws {
        let sut = try page(p, EngineHarness())
        #expect(throws: Never.self) { try sut.find(text: "SETTINGS") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.settingsHeaderTitle(p)) }
        #expect(throws: Never.self) { try sut.find(text: "Settings save at once.") }
    }

    @Test(arguments: SettingsPage.all)
    func everyPageShowsItsMainCard(_ p: SettingsPage) throws {
        let sut = try page(p, EngineHarness())
        switch p {
        case .general: #expect(throws: Never.self) { try sut.find(GeneralTab.self) }
        case let .habit(id): try expectHabitTab(id, in: sut)
        case .quickReminders: #expect(throws: Never.self) { try sut.find(QuickSettingsCard.self) }
        case .tracker: #expect(throws: Never.self) { try sut.find(TrackerSettingsPage.self) }
        case .timeBlocks: #expect(throws: Never.self) { try sut.find(TimeBlockSettingsPage.self) }
        case .todos: #expect(throws: Never.self) { try sut.find(TodosSettingsPage.self) }
        case .sound: #expect(throws: Never.self) { try sut.find(MeditationSoundCard.self) }
        }
    }

    private func expectHabitTab(_ id: HabitID, in sut: InspectableView<ViewType.ClassifiedView>) throws {
        switch id {
        case .water: _ = try sut.find(WaterSettingsTab.self)
        case .reading: _ = try sut.find(ReadingSettingsTab.self)
        case .meditation: _ = try sut.find(MeditationSettingsTab.self)
        case .gym: _ = try sut.find(GymSettingsTab.self)
        }
    }

    @Test(arguments: SettingsPage.all)
    func everyPageShowsItsTitleExactlyOnce(_ p: SettingsPage) throws {
        let sut = try page(p, EngineHarness())
        let title = Copywriter.settingsHeaderTitle(p)
        let count = sut.findAll(ViewType.Text.self).filter { (try? $0.string()) == title }.count
        #expect(count == 1)
    }

    @Test func headerTitlesNameTheBuddyAndTheHabit() {
        let titles = HabitID.allCases.map { Copywriter.settingsHeaderTitle(.habit($0)) }
        #expect(titles == ["Fota · water", "Boi · reading", "Shanti · meditation", "Shokti · gym"])
        #expect(Copywriter.settingsHeaderTitle(.quickReminders) == "Quick reminders")
        #expect(Copywriter.settingsHeaderTitle(.sound) == "Sound")
    }

    @Test(arguments: HabitID.allCases)
    func buddyPagesHaveTheOnSwitchBoundToTheBuddy(_ id: HabitID) throws {
        let h = EngineHarness {
            $0.prefs.water.enabled = true; $0.prefs.reading.enabled = true; $0.prefs.meditation.enabled = true; $0.prefs.gym.enabled = true
        }
        try Find.button(page(.habit(id), h), label: "\(id.name) reminders").tap()
        #expect(!h.engine.data.prefs.isEnabled(id))
    }

    @Test(arguments: [SettingsPage.general, .quickReminders, .tracker, .timeBlocks, .sound])
    func otherPagesHaveNoBuddySwitch(_ p: SettingsPage) throws {
        let sut = try page(p, EngineHarness())
        for id in HabitID.allCases {
            #expect(Find.lacks(sut, text: "\(id.name) reminders"))
        }
    }

    @Test func offBuddyDimsItsSettingsButKeepsTheSwitch() throws {
        let sut = try page(.habit(.water), EngineHarness { $0.prefs.water.enabled = false })
        #expect(try sut.find(button: "60 min").isDisabled())
        #expect(try !Find.button(sut, label: "Water reminders").isDisabled())
    }

    @Test(arguments: SettingsPage.all)
    func everyPageScrollsWithNoScrollBar(_ p: SettingsPage) throws {
        let scroll = try page(p, EngineHarness()).find(ViewType.ScrollView.self)
        #expect(try scroll.showsIndicators() == false)
    }
}
