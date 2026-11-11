import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Category table view")
struct CategoryTableViewTests {
    private func table(count: Int = 5, before: Bool = true) -> CategoryTable {
        CategoryTable((0 ..< count).map {
            CategoryTableInput(name: "Cat\($0)", colorHex: 0x4F8BF5, seconds: Double(count - $0) * 3600, previousSeconds: before ? 3600 : nil)
        })
    }

    @Test func showsTotalAndSummary() throws {
        let sut = try CategoryTableView(table: table(), summary: "logged · 5 categories").inspect()
        #expect(throws: Never.self) { try sut.find(text: "15h 0m") }
        #expect(throws: Never.self) { try sut.find(text: "logged · 5 categories") }
    }

    @Test func showsOneRowPerCategory() throws {
        let sut = try CategoryTableView(table: table(count: 7), summary: "").inspect()
        #expect(sut.findAll(CategoryTableRowView.self).count == 7)
    }

    @Test func showsPercentText() throws {
        let sut = try CategoryTableView(table: table(count: 2), summary: "").inspect()
        #expect(throws: Never.self) { try sut.find(text: "67%") }
        #expect(throws: Never.self) { try sut.find(text: "33%") }
    }

    @Test func oneColumnKeepsEveryRowInOneStack() {
        let columns = CategoryTableView.split(table(count: 5).rows, columns: 1)
        #expect(columns.map(\.count) == [5])
    }

    @Test func twoColumnsSplitRowsInOrderLargerFirst() {
        let columns = CategoryTableView.split(table(count: 5).rows, columns: 2)
        #expect(columns.map(\.count) == [3, 2])
        #expect(columns.flatMap { $0 }.map(\.name) == ["Cat0", "Cat1", "Cat2", "Cat3", "Cat4"])
    }

    @Test func twoColumnsRenderBothColumnsWithAllRows() throws {
        let sut = try CategoryTableView(table: table(count: 10), summary: "", columns: 2).inspect()
        #expect(sut.findAll(CategoryTableRowView.self).count == 10)
        #expect(try sut.vStack().hStack(2).forEach(0).count == 2)
    }

    @Test func changeColumnShownWhenRequested() throws {
        let sut = try CategoryTableView(table: table(count: 2), summary: "", showsChange: true).inspect()
        #expect(throws: Never.self) { try sut.find(text: "+1h 0m") }
    }

    @Test func changeColumnHiddenByDefault() throws {
        let sut = try CategoryTableView(table: table(count: 2), summary: "").inspect()
        #expect(throws: (any Error).self) { try sut.find(text: "+1h 0m") }
    }

    @Test func emptyTableShowsNoRows() throws {
        let sut = try CategoryTableView(table: CategoryTable([]), summary: "").inspect()
        #expect(sut.findAll(CategoryTableRowView.self).isEmpty)
    }
}
