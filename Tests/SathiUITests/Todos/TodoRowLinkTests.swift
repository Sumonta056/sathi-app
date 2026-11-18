import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Todo row links")
struct TodoRowLinkTests {
    private let title = "https://console.typesafe.ai/homen : Try jev"
    private let link = URL(string: "https://console.typesafe.ai/homen")!

    @Test func theAttributedTitleShowsTheShortLabelAndKeepsTheText() {
        let text = TodoRow.attributedTitle(TodoTitlePart.parts(of: title))
        #expect(String(text.characters) == "console.typesafe.ai/homen : Try jev")
    }

    @Test func onlyTheLinkPartCarriesTheURL() {
        let text = TodoRow.attributedTitle([.link(label: "console.typesafe.ai/homen", url: link), .text(" : Try jev")])
        let runs = text.runs.map { (String(text[$0.range].characters), $0.link) }
        #expect(runs.map(\.0) == ["console.typesafe.ai/homen", " : Try jev"])
        #expect(runs.map(\.1) == [link, nil])
    }

    @Test func plainTextCarriesNoLink() {
        let text = TodoRow.attributedTitle([.text("Buy milk")])
        #expect(String(text.characters) == "Buy milk")
        #expect(text.runs.allSatisfy { $0.link == nil })
    }

    @Test func theOpenActionOpensAWebLinkAndTouchesNoTodo() async {
        let h = await EngineHarness.pageFixture()
        _ = TodoRow.openAction(h.engine)(link)
        #expect(h.links.opened == [link])
        #expect(h.todos.calls.isEmpty)
    }

    @Test func theOpenActionOpensNothingForAFileLink() async throws {
        let h = await EngineHarness.pageFixture()
        _ = try TodoRow.openAction(h.engine)(#require(URL(string: "file:///tmp/x")))
        #expect(h.links.opened.isEmpty)
    }

    @Test func aRowWithALinkShowsTheShortLabel() async throws {
        let h = await EngineHarness.pageFixture()
        let sut = try hosted(TodoRow(todo: makeTodo("a", title), canEdit: true, onSelect: {}), h).inspect()
        let shown = try sut.find(viewWithAccessibilityIdentifier: "todos.row.title.a")
        #expect(throws: Never.self) { try shown.find(text: "console.typesafe.ai/homen : Try jev") }
    }
}
