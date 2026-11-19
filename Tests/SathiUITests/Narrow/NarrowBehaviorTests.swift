import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Narrow layout behavior")
struct NarrowBehaviorTests {
    private typealias Fix = ActivityViewSupport

    private final class Box {
        var on = true
        var binding: Binding<Bool> { Binding(get: { self.on }, set: { self.on = $0 }) }
    }

    private func overlay(_ box: Box, _ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        try MainSidebarOverlay(route: MainRoute(.dashboard(.day)), isShown: box.binding)
            .environmentObject(EngineHarness().engine)
            .environment(\.mainLayout, layout)
            .inspect()
    }

    @Test func railButtonOpensTheSidebarOverlayWhenNarrow() throws {
        let box = Box()
        box.on = false
        let sut = try MainSidebar(route: MainRoute(.dashboard(.day)), isOpen: .constant(true)) { box.on = true }
            .environmentObject(EngineHarness().engine)
            .environment(\.mainLayout, NarrowSupport.narrow)
            .inspect()
        try sut.find(SidebarRail.self).find(SidebarToggleButton.self).find(ViewType.Button.self).tap()
        #expect(box.on)
    }

    @Test func openOverlayShowsTheFullSidebarList() throws {
        let sut = try overlay(Box(), NarrowSupport.narrow)
        #expect(throws: Never.self) { try sut.find(MainSidebarList.self) }
        #expect(throws: Never.self) { try sut.find(MainLogo.self) }
    }

    @Test func aClickOnTheDimLayerClosesTheOverlay() throws {
        let box = Box()
        let sut = try overlay(box, NarrowSupport.narrow)
        try sut.find(MainDim.self).find(ViewType.Color.self).callOnTapGesture()
        #expect(!box.on)
    }

    @Test func aPageChangeClosesTheOverlay() throws {
        let box = Box()
        let sut = try overlay(box, NarrowSupport.narrow)
        try sut.find(ViewType.ZStack.self).callOnChange(newValue: MainPage.dashboard(.week))
        #expect(!box.on)
    }

    @Test func goingBackToWideClosesAndHidesTheOverlay() throws {
        let box = Box()
        let sut = try overlay(box, NarrowSupport.wide)
        #expect((try? sut.find(MainSidebarList.self)) == nil)
        try sut.find(ViewType.ZStack.self).callOnChange(newValue: false)
        #expect(!box.on)
    }

    @Test func drawerClosesOnAClickOutsideAndOnEsc() throws {
        let box = Box()
        let sut = try MainDrawer(close: { box.on = false }, content: { Text(verbatim: "Edit") }).inspect()
        try sut.find(MainDim.self).find(ViewType.Color.self).callOnTapGesture()
        #expect(!box.on)
        box.on = true
        let esc = try sut.find(MainDim.self).find(ViewType.Button.self)
        try esc.tap()
        #expect(!box.on)
    }

    @Test func activitiesPageHostsTheDrawerOutsideTheDayView() throws {
        let sut = try ActivityDayView(
            day: Fix.day(), overview: ActivityDayOverview(Fix.day(), loggedChange: .up(0)), categories: ActivityCategory.defaults,
            calendar: Fix.calendar, calendars: Fix.calendars, drawerHosted: true, editing: .activity(Fix.items[0].id)
        )
        .environment(\.mainLayout, NarrowSupport.narrow)
        .inspect()
        #expect((try? sut.find(viewWithAccessibilityIdentifier: MainLayout.drawerIdentifier)) == nil)
        #expect((try? sut.find(ActivityEditPanel.self)) == nil)
    }

    private func calendarEdit(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        let coding = Activity(text: "Coding", category: "Coding", start: day(2026, 3, 4, 10), end: day(2026, 3, 4, 11))
        let h = EngineHarness(at: day(2026, 3, 4, 12), activities: InMemoryActivityStore(activities: [coding])) {
            $0.prefs.tracker.isOn = true
        }
        let cal = h.engine.rangeCalendar
        let range = CalendarPageRange.containing(day(2026, 3, 4, 12), kind: .week, calendar: cal)
        let edit = CalendarActivityEdit(day: DayKey(coding.start, calendar: cal), target: .activity(coding.id))
        return try CalendarPage(range: range, editing: edit).environmentObject(h.engine).environment(\.mainLayout, layout).inspect()
    }

    @Test func calendarEditPanelIsADrawerWhenNarrow() throws {
        let drawer = try calendarEdit(NarrowSupport.narrow).find(viewWithAccessibilityIdentifier: MainLayout.drawerIdentifier)
        #expect(throws: Never.self) { try drawer.find(ActivityEditPanel.self) }
    }

    @Test func calendarEditPanelStaysBesideTheGridWhenWide() throws {
        let sut = try calendarEdit(NarrowSupport.wide)
        #expect(throws: Never.self) { try sut.find(ActivityEditPanel.self) }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: MainLayout.drawerIdentifier)) == nil)
    }
}
