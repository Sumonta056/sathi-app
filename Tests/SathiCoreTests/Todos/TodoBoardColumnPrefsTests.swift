import Foundation
@testable import SathiCore
import Testing

@Suite("TodoBoardColumnPrefs")
struct TodoBoardColumnPrefsTests {
    private func prefs(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func defaults() {
        let p = TodoPrefs()
        #expect(p.boardColumns == .auto)
        #expect(p.boardLayouts.isEmpty)
    }

    @Test func choiceCountsAndRawValues() {
        #expect(TodoBoardColumnChoice.auto.count == nil)
        #expect(TodoBoardColumnChoice.two.count == 2)
        #expect(TodoBoardColumnChoice.three.count == 3)
        #expect(TodoBoardColumnChoice.four.count == 4)
        #expect(TodoBoardColumnChoice.allCases.map(\.rawValue) == ["auto", "two", "three", "four"])
    }

    @Test func oldFileWithoutTheKeysLoadsDefaults() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"hiddenListIDs":["a"],"allView":"list"}}"#)
        #expect(p.todos.boardColumns == .auto)
        #expect(p.todos.boardLayouts.isEmpty)
        #expect(p.todos.isOn)
        #expect(p.todos.allView == .list)
    }

    @Test func anUnknownChoiceFallsBackToAutoAndKeepsOtherPrefs() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"hiddenListIDs":["a"],"listOrder":["b"],"boardColumns":"five","boardLayouts":{"3":[["x"]]}}}"#)
        #expect(p.todos.boardColumns == .auto)
        #expect(p.todos.isOn)
        #expect(p.todos.hiddenListIDs == ["a"])
        #expect(p.todos.listOrder == ["b"])
        #expect(p.todos.boardLayouts == ["3": [["x"]]])
    }

    @Test func aWrongTypeBoardLayoutsLoadsEmptyAndTheFileStillLoads() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"boardColumns":"two","boardLayouts":"oops"}}"#)
        #expect(p.todos.boardLayouts.isEmpty)
        #expect(p.todos.boardColumns == .two)
        #expect(p.todos.isOn)
    }

    @Test func aWrongTypeChoiceFallsBackToAuto() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"boardColumns":3}}"#)
        #expect(p.todos.boardColumns == .auto)
        #expect(p.todos.isOn)
    }

    @Test func savedValuesLoad() throws {
        let p = try prefs(#"{"todos":{"boardColumns":"four","boardLayouts":{"2":[["a"],["b"]],"4":[["a"],[],["b"],[]]}}}"#)
        #expect(p.todos.boardColumns == .four)
        #expect(p.todos.boardLayouts["2"] == [["a"], ["b"]])
        #expect(p.todos.boardLayouts["4"] == [["a"], [], ["b"], []])
    }

    @Test func roundTrips() throws {
        var p = Prefs()
        p.todos.boardColumns = .three
        p.todos.boardLayouts = ["3": [["a", "b"], ["c"], []], "2": [["x"], ["y"]]]
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.todos == p.todos)
    }
}
