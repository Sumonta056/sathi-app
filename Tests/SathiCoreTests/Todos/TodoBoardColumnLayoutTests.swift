import Foundation
@testable import SathiCore
import Testing

@Suite("TodoBoardColumnLayout")
struct TodoBoardColumnLayoutTests {
    private typealias Layout = TodoBoardColumnLayout

    @Test(arguments: [
        (1000.0, 3, 3), (1000.0, 4, 4), (700.0, 4, 3), (460.0, 3, 2), (220.0, 3, 1),
        (100.0, 3, 1), (900.0, 2, 2), (2000.0, 3, 3)
    ])
    func fitIsHowManyColumnsFitCappedAtThePickedCount(_ width: Double, _ count: Int, _ expected: Int) {
        #expect(Layout.fit(width: width, count: count, min: 220, gap: 16) == expected)
    }

    @Test(arguments: [0.0, -50.0, Double.infinity, -Double.infinity, Double.nan])
    func fitIsOneForAWidthThatIsNotUsable(_ width: Double) {
        #expect(Layout.fit(width: width, count: 3, min: 220, gap: 16) == 1)
    }

    @Test func assignKeepsTheSavedOrder() {
        let r = Layout.assign(lists: ["a", "b", "c", "d"], saved: [["c", "a"], ["d", "b"]], count: 2, fit: 2)
        #expect(r.columns == [["c", "a"], ["d", "b"]])
        #expect(r.unplaced.isEmpty)
    }

    @Test func aNewListIsUnplaced() {
        let r = Layout.assign(lists: ["a", "b", "n"], saved: [["a"], ["b"]], count: 2, fit: 2)
        #expect(r.columns == [["a"], ["b"]])
        #expect(r.unplaced == ["n"])
    }

    @Test func newListsKeepTheListOrder() {
        let r = Layout.assign(lists: ["x", "a", "y"], saved: [["a"], []], count: 2, fit: 2)
        #expect(r.unplaced == ["x", "y"])
    }

    @Test func aGoneListIsDropped() {
        let r = Layout.assign(lists: ["a", "b"], saved: [["a", "gone"], ["x", "b"]], count: 2, fit: 2)
        #expect(r.columns == [["a"], ["b"]])
        #expect(r.unplaced.isEmpty)
    }

    @Test func noSavedLayoutPutsEveryListInUnplaced() {
        let r = Layout.assign(lists: ["a", "b", "c"], saved: [], count: 3, fit: 3)
        #expect(r.columns == [[], [], []])
        #expect(r.unplaced == ["a", "b", "c"])
    }

    @Test func foldAtFitTwoOfThreeMovesColumnThreeToUnplacedInOrder() {
        let r = Layout.assign(lists: ["a", "b", "c", "d", "e"], saved: [["a"], ["b"], ["c", "d", "e"]], count: 3, fit: 2)
        #expect(r.columns == [["a"], ["b"]])
        #expect(r.unplaced == ["c", "d", "e"])
    }

    @Test func foldAtFitOneMovesColumnsTwoAndThreeInOrder() {
        let r = Layout.assign(lists: ["a", "b", "c"], saved: [["a"], ["b"], ["c"]], count: 3, fit: 1)
        #expect(r.columns == [["a"]])
        #expect(r.unplaced == ["b", "c"])
    }

    @Test func aFoldedColumnLeavesTheSavedLayoutUntouched() {
        let saved = [["a"], ["b"], ["c"]]
        _ = Layout.assign(lists: ["a", "b", "c"], saved: saved, count: 3, fit: 2)
        #expect(saved == [["a"], ["b"], ["c"]])
    }

    @Test func wideAgainBringsTheSavedLayoutBack() {
        let saved = [["a"], ["b"], ["c"]]
        let r = Layout.assign(lists: ["a", "b", "c"], saved: saved, count: 3, fit: 3)
        #expect(r.columns == saved)
        #expect(r.unplaced.isEmpty)
    }

    @Test func movedInsideAColumn() {
        let r = Layout.moved(shown: [["a", "b", "c"], ["d"]], id: "c", column: 0, before: "a", count: 2)
        #expect(r == [["c", "a", "b"], ["d"]])
    }

    @Test func movedAcrossColumns() {
        let r = Layout.moved(shown: [["a", "b"], ["c", "d"]], id: "a", column: 1, before: "d", count: 2)
        #expect(r == [["b"], ["c", "a", "d"]])
    }

    @Test func movedToTheEndOfAColumn() {
        let r = Layout.moved(shown: [["a", "b"], ["c"]], id: "a", column: 1, before: nil, count: 2)
        #expect(r == [["b"], ["c", "a"]])
    }

    @Test func movedIntoAnEmptyColumn() {
        let r = Layout.moved(shown: [["a", "b"], []], id: "b", column: 1, before: nil, count: 2)
        #expect(r == [["a"], ["b"]])
    }

    @Test func movedBeforeAnUnknownListIsNil() {
        let r = Layout.moved(shown: [["a", "b"], ["c"]], id: "a", column: 1, before: "zzz", count: 2)
        #expect(r == nil)
    }

    @Test func movedStartsFromWhatIsShownSoNewListsGetAPlace() {
        let r = Layout.moved(shown: [["a", "n"], ["b"]], id: "b", column: 0, before: "n", count: 2)
        #expect(r == [["a", "b", "n"], []])
    }

    @Test func movedDropsTheGoneListsBecauseTheyAreNotShown() {
        let r = Layout.moved(shown: [["a"], ["b"]], id: "a", column: 1, before: nil, count: 2)
        #expect(r == [[], ["b", "a"]])
    }
}
