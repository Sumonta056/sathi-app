import Foundation
@testable import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("TodoBoardCarryOver")
struct TodoBoardCarryOverTests {
    private typealias Layout = TodoBoardColumnLayout

    @Test func fitWithAHugeFiniteWidthDoesNotTrapAndIsCappedAtTheCount() {
        #expect(Layout.fit(width: 1e300, count: 3, min: 220, gap: 16) == 3)
        #expect(Layout.fit(width: Double.greatestFiniteMagnitude, count: 4, min: 220, gap: 16) == 4)
    }

    @Test func fitWithATinyMinimumAndHugeWidthDoesNotTrap() {
        #expect(Layout.fit(width: 1e300, count: 2, min: 1e-300, gap: 1e-300) == 2)
    }

    @Test func movedIsNilWhenTheIdIsNotShown() {
        #expect(Layout.moved(shown: [["a"], ["b"]], id: "zzz", column: 0, before: nil, count: 2) == nil)
        #expect(Layout.moved(shown: [["a"], ["b"]], id: "zzz", column: 1, before: "b", count: 2) == nil)
    }

    @Test func aMoveOfAnUnshownIdSavesNothing() {
        let h = EngineHarness()
        h.engine.setTodoBoardColumns(.two)
        h.engine.moveTodoBoard("zzz", column: 1, before: nil, shown: [["a"], ["b"]])
        #expect(h.engine.data.prefs.todos.boardLayouts.isEmpty)
    }

    private func savedHarness() async -> EngineHarness {
        let h = await EngineHarness.pageFixture(allView: .board)
        h.engine.setTodoBoardColumns(.three)
        h.engine.data.prefs.todos.boardLayouts["3"] = [["inbox"], ["work"], ["ro", "gone"]]
        return h
    }

    @Test func aSavedListThatIsNotOnScreenKeepsItsColumn() async {
        let h = await savedHarness()
        h.engine.moveTodoBoard("inbox", column: 1, before: "work", shown: [["inbox"], ["work"], []])
        let saved = h.engine.data.prefs.todos.boardLayouts["3"] ?? []
        #expect(saved.count == 3)
        #expect(saved[2].contains("ro"))
        #expect(saved[1] == ["inbox", "work"])
        #expect(saved[0].isEmpty)
    }

    @Test func aListThatIsGoneIsDroppedOnTheNextMove() async {
        let h = await savedHarness()
        h.engine.moveTodoBoard("inbox", column: 1, before: "work", shown: [["inbox"], ["work"], []])
        let saved = h.engine.data.prefs.todos.boardLayouts["3"] ?? []
        #expect(!saved.flatMap { $0 }.contains("gone"))
    }

    @Test func theKeptListShowsInItsColumnWhenItComesBack() async {
        let h = await savedHarness()
        h.engine.moveTodoBoard("inbox", column: 1, before: "work", shown: [["inbox"], ["work"], []])
        let saved = h.engine.data.prefs.todos.boardLayouts["3"] ?? []
        let r = Layout.assign(lists: ["inbox", "work", "ro"], saved: saved, count: 3, fit: 3)
        #expect(r.columns[2] == ["ro"])
        #expect(r.unplaced.isEmpty)
    }

    @Test func theKeptListSavesToDisk() async {
        let h = await savedHarness()
        h.engine.moveTodoBoard("inbox", column: 1, before: "work", shown: [["inbox"], ["work"], []])
        #expect(h.store.prefs.todos.boardLayouts["3"]?[2].contains("ro") == true)
    }

    @Test func aHiddenSavedListKeepsItsPlaceNextToAShownOneInTheSameColumn() async {
        let h = await EngineHarness.pageFixture(allView: .board)
        h.engine.setTodoBoardColumns(.two)
        h.engine.data.prefs.todos.boardLayouts["2"] = [["inbox"], ["ro", "work"]]
        h.engine.moveTodoBoard("inbox", column: 1, before: "work", shown: [["inbox"], ["work"]])
        let col = (h.engine.data.prefs.todos.boardLayouts["2"] ?? [])[1]
        #expect(Set(col) == ["inbox", "ro", "work"])
        let at = { (id: String) in col.firstIndex(of: id) ?? -1 }
        #expect(at("inbox") < at("work"))
        #expect(at("ro") < at("work"))
    }
}
