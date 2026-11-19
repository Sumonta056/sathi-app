import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Sidebar order")
struct SidebarOrderTests {
    private static let pages = ["Dashboard", "Activities", "To-dos", "Calendar"]
    private static let headings = ["Dashboard", "Activities", "PLAN", "To-dos", "Calendar", "SETTINGS"]

    private func harness(todos: Bool, calendar: Bool) -> EngineHarness {
        EngineHarness {
            $0.prefs.todos.isOn = todos
            $0.prefs.calendarPage.isOn = calendar
        }
    }

    private func dueItems(_ n: Int) -> [Todo] {
        (0 ..< n).map { makeTodo("t\($0)", list: "inbox", due: dateOnlyDue()) }
    }

    private func sidebar(
        _ h: EngineHarness,
        _ route: MainRoute? = nil,
        open: Bool = true
    ) throws -> InspectableView<ViewType.ClassifiedView> {
        let r = route ?? MainRoute(.dashboard(.day))
        return try MainSidebar(route: r, isOpen: .constant(open)).environmentObject(h.engine).inspect()
    }

    private func texts(_ h: EngineHarness) throws -> [String] {
        try sidebar(h).findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    private func railLabels(_ h: EngineHarness) throws -> [String] {
        try sidebar(h, open: false).findAll(where: { (try? $0.accessibilityLabel().string()).map(Self.pages.contains) == true })
            .compactMap { try? $0.accessibilityLabel().string() }
    }

    @Test func fullSidebarListsDashboardActivitiesThenThePlanGroupThenSettings() throws {
        let shown = try texts(harness(todos: true, calendar: true))
        #expect(Array(shown.filter(Self.headings.contains).prefix(6)) == Self.headings)
    }

    @Test func todayAndReportsItemsAreGone() throws {
        let shown = try texts(harness(todos: true, calendar: true))
        #expect(!shown.contains("Today"))
        #expect(!shown.contains("Reports"))
    }

    @Test func planHeadingHidesWhenTodosAndCalendarAreOff() throws {
        let shown = try texts(harness(todos: false, calendar: false))
        #expect(!shown.contains("PLAN"))
        #expect(shown.filter(["Dashboard", "Activities", "SETTINGS"].contains) == ["Dashboard", "Activities", "SETTINGS"])
    }

    @Test func planHeadingShowsWithOnlyCalendarOn() throws {
        let shown = try texts(harness(todos: false, calendar: true))
        let order = ["Dashboard", "Activities", "PLAN", "Calendar", "SETTINGS"]
        #expect(shown.filter(order.contains) == order)
    }

    @Test func planHeadingShowsWithOnlyTodosOn() throws {
        let shown = try texts(harness(todos: true, calendar: false))
        let order = ["Dashboard", "Activities", "PLAN", "To-dos", "SETTINGS"]
        #expect(Array(shown.filter(order.contains).prefix(5)) == order)
        #expect(!shown.contains("Calendar"))
    }

    @Test func dashboardItemOpensTheDashboardOnDay() throws {
        let route = MainRoute(.activities(nil))
        try Find.button(sidebar(harness(todos: false, calendar: false), route), holding: "Dashboard").tap()
        #expect(route.page == .dashboard(.day))
    }

    @Test(arguments: [ReportRange.day, .week, .month])
    func dashboardItemIsSelectedOnEveryRange(_ range: ReportRange) throws {
        let sut = try sidebar(harness(todos: false, calendar: false), MainRoute(.dashboard(range)))
        #expect(try A11y.isSelected(Find.button(sut, holding: "Dashboard")))
        #expect(try !A11y.isSelected(Find.button(sut, holding: "Activities")))
    }

    @Test func todosItemShowsTheDueCountBadge() async throws {
        let h = await EngineHarness.todosReady(items: dueItems(3))
        let item = try Find.button(sidebar(h), holding: "To-dos")
        let badge = try item.find(viewWithAccessibilityIdentifier: "sidebar.todosBadge")
        #expect(throws: Never.self) { try badge.find(text: "3") }
    }

    @Test func noBadgeAtZero() async {
        let h = await EngineHarness.todosReady(items: [makeTodo("later", due: dateOnlyDue(on: 5))])
        #expect((try? sidebar(h).find(viewWithAccessibilityIdentifier: "sidebar.todosBadge")) == nil)
    }

    @Test func noBadgeWithoutAccess() async {
        let h = await EngineHarness.todosReady(items: dueItems(3), access: .denied)
        #expect((try? sidebar(h).find(viewWithAccessibilityIdentifier: "sidebar.todosBadge")) == nil)
    }

    @Test func railShowsThePagesInTheSameOrder() throws {
        let labels = try railLabels(harness(todos: true, calendar: true))
        #expect(Array(labels.prefix(4)) == Self.pages)
    }

    @Test func railHasNoHeadingText() throws {
        let shown = try sidebar(harness(todos: true, calendar: true), open: false)
            .findAll(ViewType.Text.self).compactMap { try? $0.string() }
        #expect(!shown.contains("PLAN"))
    }

    @Test func railDashboardOpensTheDashboardOnDay() throws {
        let route = MainRoute(.activities(nil))
        try Find.button(sidebar(harness(todos: false, calendar: false), route, open: false), label: "Dashboard").tap()
        #expect(route.page == .dashboard(.day))
    }

    @Test func railShowsTheTodosDotWithItsLabel() async throws {
        let h = await EngineHarness.todosReady(items: dueItems(3))
        let dot = try sidebar(h, open: false).find(viewWithAccessibilityIdentifier: "rail.todosDot")
        #expect(try dot.accessibilityLabel().string() == "3 due today")
    }

    @Test func railHidesTheTodosDotAtZero() async {
        let h = await EngineHarness.todosReady(items: [])
        #expect((try? sidebar(h, open: false).find(viewWithAccessibilityIdentifier: "rail.todosDot")) == nil)
    }

    private func railDividers(_ h: EngineHarness) throws -> Int {
        try sidebar(h, open: false).findAll(where: { (try? $0.accessibilityIdentifier()) == "rail.divider" }).count
    }

    @Test func railHasOneDividerWhenThePlanGroupIsEmpty() throws {
        #expect(try railDividers(harness(todos: false, calendar: false)) == 1)
    }

    @Test func railAddsADividerBeforeThePlanItems() throws {
        #expect(try railDividers(harness(todos: false, calendar: true)) == 2)
    }

    @Test func todosItemSpeaksTheDueCount() async throws {
        let h = await EngineHarness.todosReady(items: dueItems(3))
        let item = try Find.button(sidebar(h), holding: "To-dos")
        #expect(try item.accessibilityLabel().string() == "To-dos, 3 due today")
    }
}
