import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Narrow layout")
struct NarrowLayoutTests {
    private typealias Fix = ActivityViewSupport

    private final class Box {
        var open = true
        var binding: Binding<Bool> { Binding(get: { self.open }, set: { self.open = $0 }) }
    }

    private func has(_ sut: InspectableView<ViewType.ClassifiedView>, id: String) -> Bool {
        (try? sut.find(viewWithAccessibilityIdentifier: id)) != nil
    }

    @Test func narrowSidebarShowsTheRailAndKeepsTheSavedChoice() throws {
        let box = Box()
        let sut = try MainSidebar(route: MainRoute(.dashboard(.day)), isOpen: box.binding)
            .environmentObject(EngineHarness().engine)
            .environment(\.mainLayout, NarrowSupport.narrow)
            .inspect()
        #expect(throws: Never.self) { try sut.find(SidebarRail.self) }
        #expect((try? sut.find(MainLogo.self)) == nil)
        #expect(box.open)
    }

    @Test func wideSidebarStillShowsTheSavedOpenList() throws {
        let box = Box()
        let sut = try MainSidebar(route: MainRoute(.dashboard(.day)), isOpen: box.binding)
            .environmentObject(EngineHarness().engine)
            .environment(\.mainLayout, NarrowSupport.wide)
            .inspect()
        #expect(throws: Never.self) { try sut.find(MainLogo.self) }
        #expect((try? sut.find(SidebarRail.self)) == nil)
    }

    @Test func todayBuddyGridHasTwoColumnsWhenNarrowAndFourWhenWide() {
        #expect(TodayBuddyGrid.columnCount(NarrowSupport.narrow) == 2)
        #expect(TodayBuddyGrid.columnCount(NarrowSupport.drawerOnly) == UIMetrics.todayBuddyColumns)
        #expect(TodayBuddyGrid.columnCount(NarrowSupport.wide) == UIMetrics.todayBuddyColumns)
        #expect(UIMetrics.todayBuddyColumns == 4)
    }

    private func dayView(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        try ActivityDayView(
            day: Fix.day(), overview: ActivityDayOverview(Fix.day(), loggedChange: .up(0)), categories: ActivityCategory.defaults,
            calendar: Fix.calendar, calendars: Fix.calendars, editing: .activity(Fix.items[0].id)
        )
        .environment(\.mainLayout, layout)
        .inspect()
    }

    @Test func activitiesEditPanelIsADrawerBelowElevenHundred() throws {
        for layout in [NarrowSupport.narrow, NarrowSupport.drawerOnly] {
            let sut = try dayView(layout)
            let drawer = try sut.find(viewWithAccessibilityIdentifier: MainLayout.drawerIdentifier)
            #expect(throws: Never.self) { try drawer.find(ActivityEditPanel.self) }
        }
    }

    @Test func activitiesEditPanelStaysBesideTheListWhenWide() throws {
        let sut = try dayView(NarrowSupport.wide)
        #expect(throws: Never.self) { try sut.find(ActivityEditPanel.self) }
        #expect(!has(sut, id: MainLayout.drawerIdentifier))
    }

    private func calendarPage(_ layout: MainLayout, narrowStats: Bool = false) throws -> InspectableView<ViewType.ClassifiedView> {
        let coding = Activity(text: "Coding", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 11))
        let h = EngineHarness(at: day(2026, 3, 4, 12), activities: InMemoryActivityStore(activities: [coding])) {
            $0.prefs.tracker.isOn = true
            $0.prefs.calendarPage.sidePanelShown = true
            $0.prefs.calendarPage.sidePanelShownWeek = true
        }
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: .week, calendar: h.engine.rangeCalendar)
        return try CalendarPage(range: range, narrowStats: narrowStats).environmentObject(h.engine).environment(\.mainLayout, layout).inspect()
    }

    @Test func calendarStatsPanelStartsHiddenWhenNarrowEvenIfSavedShown() throws {
        let sut = try calendarPage(NarrowSupport.narrow)
        #expect(!has(sut, id: MainLayout.floatingIdentifier))
        #expect((try? sut.find(CalendarStatsPanel.self)) == nil)
    }

    @Test func calendarStatsPanelFloatsOverTheGridWhenNarrow() throws {
        let sut = try calendarPage(NarrowSupport.narrow, narrowStats: true)
        let floating = try sut.find(viewWithAccessibilityIdentifier: MainLayout.floatingIdentifier)
        #expect(throws: Never.self) { try floating.find(CalendarStatsPanel.self) }
    }

    @Test func calendarStatsPanelStaysBesideTheGridWhenWide() throws {
        let sut = try calendarPage(NarrowSupport.wide)
        #expect(throws: Never.self) { try sut.find(CalendarStatsPanel.self) }
        #expect(!has(sut, id: MainLayout.floatingIdentifier))
    }

    private func reports(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        try ReportsPage(range: ReportsFixture.week(), selected: nil)
            .environmentObject(ReportsFixture.harness().engine)
            .environment(\.mainLayout, layout)
            .inspect()
    }

    @Test func reportsCardsStackInAColumnWhenNarrow() throws {
        let sut = try reports(NarrowSupport.narrow)
        let stack = try sut.find(viewWithAccessibilityIdentifier: MainLayout.stackedIdentifier)
        #expect(throws: Never.self) { try stack.find(ViewType.VStack.self) }
        #expect(throws: Never.self) { try stack.find(ReportsCategoryCard.self) }
        #expect(throws: Never.self) { try stack.find(StreakOverviewCard.self) }
    }

    @Test func reportsCardsSitSideBySideWhenWide() throws {
        let sut = try reports(NarrowSupport.wide)
        #expect(!has(sut, id: MainLayout.stackedIdentifier))
        #expect(throws: Never.self) { try sut.find(ReportsCategoryCard.self) }
    }

    private func calendarRow(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        try BlockDefaultCalendarRow()
            .environmentObject(EngineHarness().engine)
            .environment(\.mainLayout, layout)
            .inspect()
    }

    @Test func settingsCalendarRowPutsTheLabelAboveTheListWhenNarrow() throws {
        let sut = try calendarRow(NarrowSupport.narrow)
        let stack = try sut.find(viewWithAccessibilityIdentifier: MainLayout.stackedIdentifier)
        #expect(throws: Never.self) { try stack.find(ViewType.VStack.self) }
        #expect(throws: Never.self) { try stack.find(text: Copywriter.blockSettingsDefaultCalendar) }
    }

    @Test func settingsCalendarRowKeepsTheLabelBesideTheListWhenWide() throws {
        let sut = try calendarRow(NarrowSupport.wide)
        #expect(!has(sut, id: MainLayout.stackedIdentifier))
        #expect(throws: Never.self) { try sut.find(text: Copywriter.blockSettingsDefaultCalendar) }
    }
}
