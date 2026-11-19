import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todos navigation")
struct TodosNavigationTests {
    private func shown(_ h: EngineHarness) throws -> [String] {
        let sidebar = MainSidebar(route: MainRoute(.dashboard(.day)), isOpen: .constant(true)).environmentObject(h.engine)
        return try sidebar.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    private func main(_ page: MainPage, on: Bool) throws -> InspectableView<ViewType.ClassifiedView> {
        let h = EngineHarness { $0.prefs.todos.isOn = on }
        return try MainView(route: MainRoute(page)).environmentObject(h.engine).inspect()
    }

    @Test func sidebarHasNoTodosPageItemWhenOff() throws {
        let texts = try shown(EngineHarness())
        #expect(texts.filter { $0 == "To-dos" }.count == 1)
        #expect(texts.filter(["Dashboard", "Activities"].contains) == ["Dashboard", "Activities"])
    }

    @Test func sidebarShowsTodosUnderPlanAfterActivitiesWhenOn() throws {
        let texts = try shown(EngineHarness { $0.prefs.todos.isOn = true })
        #expect(texts.filter { $0 == "To-dos" }.count == 2)
        let pages = texts.filter(["Dashboard", "Activities", "PLAN", "To-dos"].contains)
        #expect(Array(pages.prefix(4)) == ["Dashboard", "Activities", "PLAN", "To-dos"])
    }

    @Test func tapOnTheTodosItemOpensThePage() throws {
        let h = EngineHarness { $0.prefs.todos.isOn = true }
        let route = MainRoute(.dashboard(.day))
        let sidebar = MainSidebar(route: route, isOpen: .constant(true)).environmentObject(h.engine)
        try Find.button(sidebar.inspect(), holding: "To-dos").tap()
        #expect(route.page == .todos)
    }

    @Test func settingsItemOpensTheTodosSettingsPage() throws {
        let h = EngineHarness()
        let route = MainRoute(.dashboard(.day))
        let sidebar = MainSidebar(route: route, isOpen: .constant(true)).environmentObject(h.engine)
        try Find.button(sidebar.inspect(), holding: "To-dos").tap()
        #expect(route.page == .settings(.todos))
    }

    @Test func closedRailLabelsTheTodosPageIconWhenOn() throws {
        let h = EngineHarness { $0.prefs.todos.isOn = true }
        let rail = MainSidebar(route: MainRoute(.dashboard(.day)), isOpen: .constant(false)).environmentObject(h.engine)
        let hits = try rail.inspect().findAll(where: { (try? $0.accessibilityLabel().string()) == "To-dos" })
        #expect(hits.count >= 2)
    }

    @Test func routeSettleSendsTodosToTodayWhenOff() {
        let route = MainRoute(.todos)
        route.settle(calendarOn: true, todosOn: false)
        #expect(route.page == .dashboard(.day))
        let on = MainRoute(.todos)
        on.settle(calendarOn: false, todosOn: true)
        #expect(on.page == .todos)
    }

    @Test func routeSettleStillSendsCalendarToTodayWhenOff() {
        let route = MainRoute(.calendar(nil))
        route.settle(calendarOn: false, todosOn: true)
        #expect(route.page == .dashboard(.day))
    }

    @Test func todosRouteShowsTodayWhenOff() throws {
        let sut = try main(.todos, on: false)
        #expect(throws: Never.self) { try sut.find(TodayPage.self) }
        #expect((try? sut.find(TodosPage.self)) == nil)
    }

    @Test func todosRouteShowsThePageWhenOn() throws {
        let sut = try main(.todos, on: true)
        #expect(throws: Never.self) { try sut.find(TodosPage.self) }
    }

    @Test func todosSettingsRouteShowsTheSettingsPage() throws {
        let sut = try main(.settings(.todos), on: false)
        #expect(throws: Never.self) { try sut.find(TodosSettingsPage.self) }
    }
}
