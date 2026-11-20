import Foundation
@testable import SathiCore
import Testing

@Suite("TodoBoardColumns")
struct TodoBoardColumnsTests {
    private let minWidth = 280.0
    private let gap = 16.0

    @Test(arguments: [
        (638.0, 2), (918.0, 3), (576.0, 2), (575.0, 1), (280.0, 1), (295.0, 1),
        (1200.0, 4), (1216.0, 4), (279.0, 1), (100.0, 1), (1500.0, 5)
    ])
    func countFollowsTheFormula(_ width: Double, _ expected: Int) {
        let formula = max(1, Int(floor((width + gap) / (minWidth + gap))))
        #expect(formula == expected)
        #expect(TodoBoardColumns.count(width: width, min: minWidth, gap: gap) == expected)
    }

    @Test(arguments: [nil, 0.0, -50.0, Double.infinity, -Double.infinity, Double.nan])
    func anUnusableWidthGivesOneColumn(_ width: Double?) {
        #expect(TodoBoardColumns.count(width: width, min: minWidth, gap: gap) == 1)
    }

    @Test func eachBoardGoesIntoTheShortestColumn() {
        #expect(TodoBoardColumns.place(heights: [100, 50, 50, 10], columns: 2, previous: nil) == [0, 1, 1, 0])
    }

    @Test func aTieGoesToTheFirstColumn() {
        #expect(TodoBoardColumns.place(heights: [10, 10, 10], columns: 2, previous: nil) == [0, 1, 0])
    }

    @Test func oneColumnTakesEveryBoard() {
        #expect(TodoBoardColumns.place(heights: [30, 20, 10], columns: 1, previous: nil) == [0, 0, 0])
    }

    @Test func zeroColumnsActLikeOne() {
        #expect(TodoBoardColumns.place(heights: [30, 20], columns: 0, previous: nil) == [0, 0])
    }

    @Test func noBoardsGiveNoColumns() {
        #expect(TodoBoardColumns.place(heights: [], columns: 3, previous: nil).isEmpty)
    }

    @Test func moreColumnsThanBoardsFillOneEach() {
        #expect(TodoBoardColumns.place(heights: [5, 5], columns: 4, previous: nil) == [0, 1])
    }

    @Test func earlierColumnsAreKeptWhenTheBoardCountMatches() {
        let previous = [1, 0, 1]
        #expect(TodoBoardColumns.place(heights: [10, 10, 10], columns: 2, previous: previous) == previous)
        #expect(TodoBoardColumns.place(heights: [500, 1, 1], columns: 2, previous: previous) == previous)
    }

    @Test func aChangedBoardCountPlacesAgain() {
        #expect(TodoBoardColumns.place(heights: [10, 10, 10], columns: 2, previous: [1, 0]) == [0, 1, 0])
        #expect(TodoBoardColumns.place(heights: [10, 10], columns: 2, previous: [1, 0, 1]) == [0, 1])
    }

    @Test func aPreviousColumnPastTheCountPlacesAgain() {
        #expect(TodoBoardColumns.place(heights: [10, 10, 10], columns: 2, previous: [0, 1, 2]) == [0, 1, 0])
    }

    @Test func aChangedHeightDoesNotMoveABoardWhileTheCountsMatch() {
        let first = TodoBoardColumns.place(heights: [10, 10, 10], columns: 2, previous: nil)
        let second = TodoBoardColumns.place(heights: [10, 400, 10], columns: 2, previous: first)
        #expect(second == first)
    }
}
