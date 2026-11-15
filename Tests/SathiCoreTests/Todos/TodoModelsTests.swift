import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Todo models")
struct TodoModelsTests {
    @Test func aDraftNeedsATitleAfterTrimming() {
        #expect(!TodoDraft(listID: "a", title: "   ", notes: "", due: nil).isValid)
        #expect(TodoDraft(listID: "a", title: " Milk ", notes: "", due: nil).isValid)
        #expect(TodoDraft(listID: "a", title: " Milk ", notes: "", due: nil).trimmedTitle == "Milk")
    }

    @Test func aListDraftNeedsANameAndAKnownColor() {
        let color = Limits.todoListColors[0]
        #expect(TodoListDraft(name: " Shopping ", colorHex: color, accountID: "ic").isValid)
        #expect(TodoListDraft(name: " Shopping ", colorHex: color, accountID: "ic").trimmedName == "Shopping")
        #expect(!TodoListDraft(name: "  ", colorHex: color, accountID: "ic").isValid)
        #expect(!TodoListDraft(name: "Shopping", colorHex: "#123456X", accountID: "ic").isValid)
    }

    @Test func theSnapshotJoinsOpenAndRecentCompleted() {
        let open = makeTodo("a")
        let done = makeTodo("b", done: true, doneAt: Date(timeIntervalSince1970: 1_800_000_000))
        let s = TodoSnapshot(lists: [makeTodoList("inbox")], open: [open], recentCompleted: [done], revision: 3)
        #expect(s.revision == 3)
        #expect(s.todos == [open, done])
        #expect(TodoSnapshot.empty.revision == 0)
        #expect(TodoSnapshot.empty.lists.isEmpty)
        #expect(TodoSnapshot.empty.todos.isEmpty)
    }

    @Test func mainPageHasATodosPage() {
        #expect(MainPage.todos == MainPage.todos)
        #expect(MainPage.todos != MainPage.today)
    }

    @Test func listColorsAreTwelveUniqueHexValues() {
        let colors = Limits.todoListColors
        #expect(colors.count == 12)
        #expect(Set(colors).count == 12)
        for c in colors {
            #expect(c.range(of: "^#[0-9A-Fa-f]{6}$", options: .regularExpression) != nil)
        }
    }

    @Test func limitValues() {
        #expect(Limits.todoCompletedDays == 30)
        #expect(Limits.todoQuickPanelMax == 3)
    }
}
