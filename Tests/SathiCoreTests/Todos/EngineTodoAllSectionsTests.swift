import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoAllSections")
struct EngineTodoAllSectionsTests {
    private func ids(_ items: [Todo]) -> [String] { items.map(\.id) }

    @Test func allGroupsItsTodosByListInSideOrder() async {
        let h = await EngineHarness.pageFixture()
        let page = h.engine.todoPage(.smart(.all))
        #expect(page.sections.map(\.list.id) == ["inbox", "work", "ro"])
        #expect(page.sections.map { ids($0.todos) } == [["f", "a", "c"], ["b", "d"], ["e"]])
    }

    @Test(arguments: [TodoSmartList.today, .scheduled, .completed])
    func otherSmartListsStayFlat(_ smart: TodoSmartList) async {
        let h = await EngineHarness.pageFixture()
        #expect(h.engine.todoPage(.smart(smart)).sections.isEmpty)
    }

    @Test func aListPageStaysFlat() async {
        let h = await EngineHarness.pageFixture()
        #expect(h.engine.todoPage(.list("inbox")).sections.isEmpty)
    }

    @Test func aHiddenListHasNoSectionOnAll() async {
        let h = await EngineHarness.todosReady(
            items: EngineHarness.pageItems,
            configure: { $0.prefs.todos.hiddenListIDs = ["work"] }
        )
        #expect(h.engine.todoPage(.smart(.all)).sections.map(\.list.id) == ["inbox"])
    }
}
