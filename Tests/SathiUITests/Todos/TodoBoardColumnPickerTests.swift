import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo board columns")
struct TodoBoardColumnPickerTests {
    private func column(_ h: EngineHarness, _ sel: TodoSelection = .smart(.all)) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodoItemsColumn(selection: sel), h).inspect()
    }

    private func picker(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try column(h).find(viewWithAccessibilityIdentifier: "todos.board.columns")
    }

    private func fixed(_ choice: TodoBoardColumnChoice) async -> EngineHarness {
        let h = await EngineHarness.pageFixture(allView: .board)
        h.engine.setTodoBoardColumns(choice)
        return h
    }

    @Test func thePickerShowsOnAllInBoardView() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        #expect(throws: Never.self) { try picker(h) }
    }

    @Test func thePickerIsHiddenInListView() async {
        let h = await EngineHarness.pageFixture(allView: .list)
        #expect((try? column(h).find(viewWithAccessibilityIdentifier: "todos.board.columns")) == nil)
    }

    @Test func thePickerIsHiddenOnEveryOtherPage() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        for selection in [TodoSelection.smart(.today), .smart(.scheduled), .smart(.completed), .list("inbox")] {
            let sut = try column(h, selection)
            #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.board.columns")) == nil)
        }
    }

    @Test func thePickerOffersAutoTwoThreeFour() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let p = try picker(h)
        for label in ["Auto", "2", "3", "4"] {
            #expect(throws: Never.self) { try Find.button(p, holding: label) }
        }
    }

    @Test func tappingThreeChoosesThreeColumns() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        try Find.button(picker(h), holding: "3").tap()
        #expect(h.engine.data.prefs.todos.boardColumns == .three)
    }

    @Test func tappingTwoAndFourAndAutoChooseThem() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        try Find.button(picker(h), holding: "2").tap()
        #expect(h.engine.data.prefs.todos.boardColumns == .two)
        try Find.button(picker(h), holding: "4").tap()
        #expect(h.engine.data.prefs.todos.boardColumns == .four)
        try Find.button(picker(h), holding: "Auto").tap()
        #expect(h.engine.data.prefs.todos.boardColumns == .auto)
    }

    @Test func theDefaultIsAutoAndHasNoColumnMarkers() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        #expect(h.engine.data.prefs.todos.boardColumns == .auto)
        let sut = try column(h)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.board.column.0")) == nil)
    }

    @Test(arguments: [(TodoBoardColumnChoice.two, 2), (.three, 3), (.four, 4)])
    func aFixedChoiceShowsExactlyThatManyColumns(_ choice: TodoBoardColumnChoice, _ n: Int) async throws {
        let sut = try await column(fixed(choice))
        for i in 0 ..< n {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.board.column.\(i)") }
        }
        #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.board.column.\(n)")) == nil)
    }

    @Test func fixedThreeKeepsEveryCardOnTheBoard() async throws {
        let h = await fixed(.three)
        h.engine.data.prefs.todos.boardLayouts["3"] = [["work"], ["inbox"], ["ro"]]
        let sut = try column(h)
        for id in ["inbox", "work", "ro"] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.board.card." + id) }
        }
    }

    @Test func autoHasNoDragMarkerOnAnyCard() async throws {
        let h = await EngineHarness.pageFixture(allView: .board)
        let sut = try column(h)
        for id in ["inbox", "work", "ro"] {
            #expect((try? sut.find(viewWithAccessibilityIdentifier: "todos.board.drag." + id)) == nil)
        }
    }

    @Test func aFixedBoardHasADragMarkerOnEveryCardHeader() async throws {
        let sut = try await column(fixed(.three))
        for id in ["inbox", "work", "ro"] {
            #expect(throws: Never.self) { try sut.find(viewWithAccessibilityIdentifier: "todos.board.drag." + id) }
        }
    }

    @Test func thePlusButtonIsNotTheDragMarker() async throws {
        let sut = try await column(fixed(.two))
        let add = try sut.find(viewWithAccessibilityIdentifier: "todos.board.add.inbox")
        #expect((try? add.find(viewWithAccessibilityIdentifier: "todos.board.drag.inbox")) == nil)
    }

    @Test(arguments: [(nil as Int?, 3, false), (2, 2, true), (3, 3, true), (4, 4, true), (3, 2, false), (4, 1, false)])
    func dragIsAllowedOnlyForAFixedCountThatFits(_ count: Int?, _ fit: Int, _ allowed: Bool) {
        #expect(TodoBoardDropTarget.canDrag(count: count, fit: fit) == allowed)
    }

    @Test func rowsStillHaveTheirOwnRowDrag() async throws {
        let sut = try await column(fixed(.three))
        #expect(!sut.findAll(TodoRow.self).isEmpty)
    }
}
