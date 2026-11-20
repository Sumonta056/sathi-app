import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("EngineTodoBoardColumns")
struct EngineTodoBoardColumnsTests {
    private let shown = [["a", "b"], ["c"]]

    @Test func choosingAColumnCountChangesPrefs() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.three)
        #expect(h.engine.data.prefs.todos.boardColumns == .three)
        h.engine.setTodoBoardColumns(.auto)
        #expect(h.engine.data.prefs.todos.boardColumns == .auto)
    }

    @Test func choosingAColumnCountSaves() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.four)
        #expect(h.store.prefs.todos.boardColumns == .four)
    }

    @Test func autoSavesNoLayout() {
        let h = EngineHarness()
        h.engine.moveTodoBoard("a", column: 1, before: nil, shown: shown)
        #expect(h.engine.data.prefs.todos.boardLayouts.isEmpty)
    }

    @Test func aMoveSavesUnderTheCurrentCount() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("a", column: 1, before: "c", shown: shown)
        #expect(h.engine.data.prefs.todos.boardLayouts == ["2": [["b"], ["a", "c"]]])
        #expect(h.store.prefs.todos.boardLayouts["2"] == [["b"], ["a", "c"]])
    }

    @Test func aMoveToTheEndSaves() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("a", column: 1, before: nil, shown: shown)
        #expect(h.engine.data.prefs.todos.boardLayouts["2"] == [["b"], ["c", "a"]])
    }

    @Test func eachCountKeepsItsOwnLayout() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("a", column: 1, before: nil, shown: shown)
        h.engine.setTodoBoardColumns(.three)
        h.engine.moveTodoBoard("c", column: 2, before: nil, shown: [["a"], ["b"], ["c"]])
        let layouts = h.engine.data.prefs.todos.boardLayouts
        #expect(layouts["2"] == [["b"], ["c", "a"]])
        #expect(layouts["3"] == [["a"], ["b"], ["c"]])
        h.engine.setTodoBoardColumns(.two)
        #expect(h.engine.data.prefs.todos.boardLayouts["2"] == [["b"], ["c", "a"]])
    }

    @Test func aSecondMoveReplacesOnlyThatCount() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("a", column: 1, before: nil, shown: shown)
        h.engine.moveTodoBoard("b", column: 1, before: "c", shown: [["b"], ["c", "a"]])
        #expect(h.engine.data.prefs.todos.boardLayouts == ["2": [[], ["b", "c", "a"]]])
    }

    @Test func aMoveBeforeAnUnknownBoardChangesNothing() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("a", column: 1, before: "zzz", shown: shown)
        #expect(h.engine.data.prefs.todos.boardLayouts.isEmpty)
    }

    @Test func aBoardMoveDoesNotChangeTheListOrder() {
        let h = EngineHarness { $0.prefs.todos.listOrder = ["b", "a", "c"] }
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("a", column: 1, before: nil, shown: shown)
        #expect(h.engine.data.prefs.todos.listOrder == ["b", "a", "c"])
    }

    @Test func switchingToAutoKeepsTheSavedLayouts() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("a", column: 1, before: nil, shown: shown)
        h.engine.setTodoBoardColumns(.auto)
        #expect(h.engine.data.prefs.todos.boardLayouts["2"] == [["b"], ["c", "a"]])
    }

    @Test func noBoardDragWhileAFoldIsActive() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.three)
        h.engine.moveTodoBoard("a", column: 1, before: nil, shown: [["a", "b"], ["c"]])
        #expect(h.engine.data.prefs.todos.boardLayouts.isEmpty)
    }

    @Test func aMoveToAColumnThatDoesNotExistChangesNothing() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("a", column: 2, before: nil, shown: shown)
        #expect(h.engine.data.prefs.todos.boardLayouts.isEmpty)
    }
}
