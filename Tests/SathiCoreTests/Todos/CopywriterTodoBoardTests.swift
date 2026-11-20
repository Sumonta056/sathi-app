@testable import SathiCore
import Testing

@Suite("CopywriterTodoBoard")
struct CopywriterTodoBoardTests {
    @Test func theAddLabelNamesTheList() {
        #expect(Copywriter.todoBoardAdd(list: "Work") == "Add to-do to Work")
    }

    @Test func theListsButtonLabelsFollowTheState() {
        #expect(Copywriter.todoHideLists == "Hide lists")
        #expect(Copywriter.todoShowLists == "Show lists")
    }

    @Test func theSwitchLabels() {
        #expect(Copywriter.todoViewList == "List")
        #expect(Copywriter.todoViewBoard == "Board")
    }
}
