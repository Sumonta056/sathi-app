import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Main view")
struct MainViewTests {
    private func main(_ page: MainPage) throws -> InspectableView<ViewType.ClassifiedView> {
        try MainView(route: MainRoute(page)).environmentObject(EngineHarness().engine).inspect()
    }

    @Test func showsTheSidebar() throws {
        #expect(throws: Never.self) { try main(.dashboard(.day)).find(MainSidebar.self) }
    }

    @Test func hasTheWindowDragStrip() throws {
        #expect(throws: Never.self) { try main(.dashboard(.day)).find(WindowDragStrip.self) }
    }

    @Test func trackerSettingsPageShowsTheTrackerSettings() throws {
        #expect(throws: Never.self) { try main(.settings(.tracker)).find(TrackerSettingsPage.self) }
    }

    @Test func generalSettingsPageShowsTheGeneralTab() throws {
        #expect(throws: Never.self) { try main(.settings(.general)).find(GeneralTab.self) }
    }

    @Test func timeBlocksSettingsPageShowsTheTimeBlockSettings() throws {
        #expect(throws: Never.self) { try main(.settings(.timeBlocks)).find(TimeBlockSettingsPage.self) }
    }

    @Test func buddySettingsPageShowsThatBuddy() throws {
        #expect(throws: Never.self) { try main(.settings(.habit(.gym))).find(GymSettingsTab.self) }
    }

    @Test func quickRemindersPageShowsTheQuickReminderCard() throws {
        #expect(throws: Never.self) { try main(.settings(.quickReminders)).find(QuickSettingsCard.self) }
    }

    @Test func soundPageShowsTheBreathingSoundCard() throws {
        #expect(throws: Never.self) { try main(.settings(.sound)).find(MeditationSoundCard.self) }
    }

    @Test func reportsPageShowsTheReports() throws {
        #expect(throws: Never.self) { try main(.dashboard(.week)).find(ReportsPage.self) }
    }

    @Test func activitiesPageShowsTheActivityReports() throws {
        #expect(throws: Never.self) { try main(.activities(nil)).find(ActivitiesPage.self) }
    }

    @Test func todayPageShowsTheTodayPage() throws {
        #expect(throws: Never.self) { try main(.dashboard(.day)).find(TodayPage.self) }
    }

    @Test func calendarRouteShowsTodayWhenTheSwitchIsOff() throws {
        #expect(throws: Never.self) { try main(.calendar(nil)).find(TodayPage.self) }
        #expect((try? main(.calendar(nil)).find(CalendarPage.self)) == nil)
    }

    @Test func calendarRouteShowsTheCalendarPageWhenOn() throws {
        let h = EngineHarness { $0.prefs.calendarPage.isOn = true }
        let sut = try MainView(route: MainRoute(.calendar(nil))).environmentObject(h.engine).inspect()
        #expect(throws: Never.self) { try sut.find(CalendarPage.self) }
    }

    @Test func routeChangeSwitchesThePage() throws {
        let route = MainRoute(.dashboard(.day))
        let view = MainView(route: route).environmentObject(EngineHarness().engine)
        route.page = .settings(.tracker)
        #expect(throws: Never.self) { try view.inspect().find(TrackerSettingsPage.self) }
    }
}
