import SathiCore
import Testing

@Suite("Category table")
struct CategoryTableTests {
    private func input(_ name: String, _ minutes: Double, before: Double? = nil, hex: UInt32 = 0x111111) -> CategoryTableInput {
        CategoryTableInput(name: name, colorHex: hex, seconds: minutes * 60, previousSeconds: before.map { $0 * 60 })
    }

    @Test func rowsAreSortedLargestFirstAndTiesKeepInputOrder() {
        let table = CategoryTable([input("B", 30), input("A", 90), input("C", 30)])
        #expect(table.rows.map(\.name) == ["A", "B", "C"])
    }

    @Test func emptyInputGivesNoRowsAndZeroTotal() {
        let table = CategoryTable([])
        #expect(table.rows.isEmpty)
        #expect(table.totalSeconds == 0)
        #expect(table.totalText == "0m")
    }

    @Test func totalAddsEveryRowAndUsesShortHours() {
        let table = CategoryTable([input("A", 186), input("B", 20)])
        #expect(table.totalSeconds == 206 * 60)
        #expect(table.totalText == "3h 26m")
    }

    @Test func hoursTextUsesShortFormat() {
        let table = CategoryTable([input("A", 186), input("B", 55)])
        #expect(table.rows.map(\.hoursText) == ["3h 6m", "55m"])
    }

    @Test func percentRoundsToNearestWholeNumber() {
        let table = CategoryTable([input("A", 2), input("B", 1)])
        #expect(table.rows.map(\.percentText) == ["67%", "33%"])
    }

    @Test func tinyCategoryShowsLessThanOnePercent() {
        let table = CategoryTable([input("A", 1000), input("B", 1)])
        #expect(table.rows.map(\.percentText) == ["100%", "<1%"])
    }

    @Test func zeroSecondRowWithoutHistoryIsDropped() {
        let table = CategoryTable([input("A", 10), input("B", 0)])
        #expect(table.rows.map(\.name) == ["A"])
    }

    @Test func zeroSecondRowWithHistoryStaysWithZeroPercent() {
        let table = CategoryTable([input("A", 10, before: 10), input("B", 0, before: 12)])
        #expect(table.rows.map(\.name) == ["A", "B"])
        #expect(table.rows[1].percentText == "0%")
        #expect(table.rows[1].changeText == "\u{2212}12m")
    }

    @Test func changeTextShowsSignedDifference() {
        let table = CategoryTable([input("A", 100, before: 60), input("B", 48, before: 60), input("C", 30, before: 30)])
        #expect(table.rows.map(\.changeText) == ["+40m", "\u{2212}12m", "0m"])
    }

    @Test func changeIsEmptyWithoutPreviousRange() {
        let table = CategoryTable([input("A", 100)])
        #expect(table.rows[0].changeText == "")
        #expect(table.rows[0].change == .none)
    }

    @Test func changeOverAnHourUsesHoursAndMinutes() {
        let table = CategoryTable([input("A", 200, before: 60)])
        #expect(table.rows[0].changeText == "+2h 20m")
    }

    @Test func colorAndSecondsPassThrough() {
        let table = CategoryTable([input("A", 5, hex: 0xFF9FB8)])
        #expect(table.rows[0].colorHex == 0xFF9FB8)
        #expect(table.rows[0].seconds == 300)
        #expect(table.rows[0].id == "A")
    }
}
