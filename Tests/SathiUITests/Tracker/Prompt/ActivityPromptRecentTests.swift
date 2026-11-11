import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity prompt recent pane")
struct ActivityPromptRecentTests {
    private func cards(_ sut: InspectableView<some BaseViewType>) -> [String] {
        Prompt.ids(sut, prefix: "prompt.recent.")
    }

    @Test func tenRecentsShowSixCardsAndShowAllTen() throws {
        let s = Prompt.state(.whatNow) { $0.recents = Prompt.recents(10) }
        let sut = try Prompt.view(s)
        #expect(cards(sut) == (0 ..< 6).map { "prompt.recent.\($0)" })
        #expect(try Prompt.buttonText(sut, "prompt.showAll") == ["Show all 10"])
        #expect(Prompt.hasText(sut, "RECENT"))
        #expect(Prompt.hasText(sut, "tap to fill"))
    }

    @Test func showAllShowsEveryRecent() throws {
        let s = Prompt.state(.whatNow) { $0.recents = Prompt.recents(10) }
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "prompt.showAll")
        let sut = try Prompt.view(s, model: model)
        #expect(cards(sut).count == 10)
        #expect(!Prompt.has(sut, "prompt.showAll"))
    }

    @Test func noShowAllWithSixOrFewer() throws {
        let s = Prompt.state(.whatNow) { $0.recents = Prompt.recents(6) }
        let sut = try Prompt.view(s)
        #expect(cards(sut).count == 6)
        #expect(!Prompt.has(sut, "prompt.showAll"))
    }

    @Test func aCardShowsTheNameTheCategoryAndTheLastLength() throws {
        let s = Prompt.state(.whatNow) { $0.recents = Prompt.recents(4) }
        let sut = try Prompt.view(s)
        #expect(Prompt.hasText(sut, "Task 3"))
        #expect(Prompt.hasText(sut, "Review · last 30 min"))
    }

    @Test func aTapFillsTextAndCategoryAndDoesNotStart() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) {
            $0.recents = Prompt.recents(4)
            $0.draft.length = .open
        }
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "prompt.recent.3")
        #expect(model.draft.text == "Task 3")
        #expect(model.draft.category == "Review")
        #expect(model.draft.length == .open)
        #expect(calls.started.isEmpty)
        #expect(calls.calls.isEmpty)
    }

    @Test func theFilledCardIsMarked() throws {
        let s = Prompt.state(.whatNow) { $0.recents = Prompt.recents(4) }
        let model = ActivityPromptModel(s)
        try Prompt.tap(Prompt.view(s, model: model), "prompt.recent.2")
        let picked = try Prompt.view(s, model: model).findAll(PromptRecentCard.self).map { try $0.actualView().filled }
        #expect(picked == [false, false, true, false])
    }

    @Test func theFirstSixCardsHaveCommandKeys() throws {
        let s = Prompt.state(.whatNow) { $0.recents = Prompt.recents(10) }
        let sut = try Prompt.view(s)
        for n in 1 ... 6 {
            #expect(Prompt.hasText(sut, "⌘\(n)"))
            let button = try sut.find(viewWithAccessibilityIdentifier: "prompt.recent.\(n - 1)").find(ViewType.Button.self, relation: .parent)
            let key = try #require(try button.modifier(PromptKey.self).actualView().shortcut)
            #expect(key.key == KeyEquivalent(Character("\(n)")))
            #expect(key.modifiers == .command)
        }
    }

    @Test func theRunningEventIsTheFirstCard() throws {
        let s = Prompt.state(.whatNow) {
            $0.recents = Prompt.recents(2)
            $0.runningEvent = Prompt.event("Design sync")
        }
        let model = ActivityPromptModel(s)
        let sut = try Prompt.view(s, model: model)
        #expect(cards(sut).count == 3)
        try Prompt.tap(sut, "prompt.recent.0")
        #expect(model.draft.text == "Design sync")
        #expect(model.draft.sourceEventID == "e1")
    }
}
