import Foundation
@testable import SathiCore
import Testing

@Suite("TodoBoardArranged")
struct TodoBoardArrangedTests {
    private typealias Layout = TodoBoardColumnLayout

    private func arranged(
        _ lists: [String], _ saved: [[String]], _ count: Int, _ fit: Int, _ heights: [String: Double]
    ) -> [[String]] {
        Layout.arranged(lists: lists, saved: saved, count: count, fit: fit, heights: heights)
    }

    @Test func aSavedLayoutIsShownInSavedOrder() {
        let r = arranged(["a", "b", "c"], [["c"], ["a", "b"], []], 3, 3, ["a": 100, "b": 100, "c": 100])
        #expect(r == [["c"], ["a", "b"], []])
    }

    @Test func aNewListGoesToTheEndOfTheShortestColumn() {
        let r = arranged(["a", "b", "n"], [["a"], ["b"]], 2, 2, ["a": 300, "b": 100, "n": 50])
        #expect(r == [["a"], ["b", "n"]])
    }

    @Test func newListsSpreadByMeasuredHeightsInListOrder() {
        let r = arranged(["x", "y", "z"], [], 2, 2, ["x": 100, "y": 100, "z": 100])
        #expect(r == [["x", "z"], ["y"]])
    }

    @Test func aTieGoesToTheFirstColumn() {
        let r = arranged(["a", "b", "n"], [["a"], ["b"]], 2, 2, ["a": 100, "b": 100, "n": 10])
        #expect(r == [["a", "n"], ["b"]])
    }

    @Test func foldedBoardsGoToTheEndOfTheShortestColumnsInOrder() {
        let saved = [["a"], ["b"], ["c", "d"]]
        let h = ["a": 100.0, "b": 300.0, "c": 100.0, "d": 100.0]
        let r = arranged(["a", "b", "c", "d"], saved, 3, 2, h)
        #expect(r == [["a", "c", "d"], ["b"]])
    }

    @Test func foldAtOneColumnStacksEverythingInOrder() {
        let r = arranged(["a", "b", "c"], [["a"], ["b"], ["c"]], 3, 1, ["a": 1, "b": 1, "c": 1])
        #expect(r == [["a", "b", "c"]])
    }

    @Test func wideAgainBringsTheSavedLayoutBack() {
        let saved = [["a"], ["b"], ["c"]]
        let h = ["a": 1.0, "b": 1.0, "c": 1.0]
        _ = arranged(["a", "b", "c"], saved, 3, 2, h)
        #expect(arranged(["a", "b", "c"], saved, 3, 3, h) == saved)
    }

    @Test func aGoneListIsNotShown() {
        let r = arranged(["a"], [["a", "gone"], []], 2, 2, ["a": 1])
        #expect(r == [["a"], []])
    }

    @Test func aMissingHeightCountsAsZero() {
        let r = arranged(["a", "n", "m"], [["a"], []], 2, 2, ["a": 10, "m": 10])
        #expect(r == [["a"], ["n", "m"]])
    }

    @Test func autoIsNotInvolvedAndColumnsAreAlwaysPaddedToFit() {
        #expect(arranged([], [], 4, 4, [:]) == [[], [], [], []])
    }
}
