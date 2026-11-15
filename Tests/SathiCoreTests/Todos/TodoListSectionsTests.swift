import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoListSections")
struct TodoListSectionsTests {
    private func list(_ id: String, account: String) -> TodoList {
        TodoList(id: id, name: id.uppercased(), colorHex: "#FF3B30", accountID: account, accountName: account, canEdit: true)
    }

    @Test func sectionsFollowTheSideColumnOrderGroupedByAccount() {
        let lists = [list("a", account: "iCloud"), list("x", account: "Work"), list("b", account: "iCloud")]
        let open = [makeTodo("1", list: "x"), makeTodo("2", list: "b"), makeTodo("3", list: "a")]
        let sections = TodoRules.listSections(lists: lists, open: open)
        #expect(sections.map(\.list.id) == ["a", "b", "x"])
    }

    @Test func eachSectionKeepsTheGivenOrderInside() {
        let lists = [list("a", account: "iCloud")]
        let open = [makeTodo("2", list: "a"), makeTodo("1", list: "a"), makeTodo("3", list: "a")]
        #expect(TodoRules.listSections(lists: lists, open: open).first?.todos.map(\.id) == ["2", "1", "3"])
    }

    @Test func aListWithNoOpenTodoHasNoSection() {
        let lists = [list("a", account: "iCloud"), list("b", account: "iCloud")]
        let sections = TodoRules.listSections(lists: lists, open: [makeTodo("1", list: "b")])
        #expect(sections.map(\.list.id) == ["b"])
    }

    @Test func aTodoOfAnUnknownListHasNoSection() {
        let lists = [list("a", account: "iCloud")]
        #expect(TodoRules.listSections(lists: lists, open: [makeTodo("1", list: "hidden")]).isEmpty)
    }

    @Test func sideOrderGroupsListsByAccountInFirstSeenOrder() {
        let lists = [list("a", account: "iCloud"), list("x", account: "Work"), list("b", account: "iCloud")]
        #expect(TodoRules.sideOrder(lists).map(\.id) == ["a", "b", "x"])
    }
}
