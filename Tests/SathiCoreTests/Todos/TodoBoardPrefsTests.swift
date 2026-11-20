import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("TodoBoardPrefs")
struct TodoBoardPrefsTests {
    private func prefs(_ json: String) throws -> Prefs {
        try JSONDecoder().decode(Prefs.self, from: Data(json.utf8))
    }

    @Test func defaults() {
        let p = TodoPrefs()
        #expect(p.allView == .board)
        #expect(!p.sideHidden)
        #expect(p.listOrder.isEmpty)
    }

    @Test func oldTodosPrefsWithoutTheKeysLoadDefaults() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"hiddenListIDs":["a"],"order":{"inbox":["x","y"]}}}"#)
        #expect(p.todos.allView == .board)
        #expect(!p.todos.sideHidden)
        #expect(p.todos.listOrder.isEmpty)
        #expect(p.todos.isOn)
    }

    @Test func anUnknownAllViewFallsBackToBoardAndKeepsOtherPrefs() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"hiddenListIDs":["a"],"order":{"inbox":["x"]},"allView":"grid"}}"#)
        #expect(p.todos.allView == .board)
        #expect(p.todos.isOn)
        #expect(p.todos.hiddenListIDs == ["a"])
        #expect(p.todos.order == ["inbox": ["x"]])
    }

    @Test func badSideAndOrderValuesFallBack() throws {
        let p = try prefs(#"{"todos":{"isOn":true,"sideHidden":"yes","listOrder":7}}"#)
        #expect(!p.todos.sideHidden)
        #expect(p.todos.listOrder.isEmpty)
        #expect(p.todos.isOn)
    }

    @Test func savedValuesLoad() throws {
        let p = try prefs(#"{"todos":{"allView":"list","sideHidden":true,"listOrder":["b","a"]}}"#)
        #expect(p.todos.allView == .list)
        #expect(p.todos.sideHidden)
        #expect(p.todos.listOrder == ["b", "a"])
    }

    @Test func roundTripsAllThree() throws {
        var p = Prefs()
        p.todos.allView = .list
        p.todos.sideHidden = true
        p.todos.listOrder = ["z", "y"]
        let back = try JSONDecoder().decode(Prefs.self, from: JSONEncoder().encode(p))
        #expect(back.todos == p.todos)
    }

    @Test @MainActor func engineSettersChangePrefs() {
        let h = EngineHarness()
        h.engine.setTodoAllView(.list)
        #expect(h.engine.data.prefs.todos.allView == .list)
        h.engine.setTodoSideHidden(true)
        #expect(h.engine.data.prefs.todos.sideHidden)
        h.engine.setTodoAllView(.board)
        h.engine.setTodoSideHidden(false)
        #expect(h.engine.data.prefs.todos.allView == .board)
        #expect(!h.engine.data.prefs.todos.sideHidden)
    }
}
