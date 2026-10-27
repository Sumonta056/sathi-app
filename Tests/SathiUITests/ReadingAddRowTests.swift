import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Reading add row")
struct ReadingAddRowTests {
    @Test func showsBothFieldsAndTheButtons() throws {
        let sut = try AddRowState().inspect(Books.harness([]))
        #expect(throws: Never.self) { try AddRowState.field(sut, "Paste a link") }
        #expect(throws: Never.self) { try AddRowState.field(sut, "Title (optional)") }
        #expect(throws: Never.self) { try sut.find(button: "Add") }
        #expect(throws: Never.self) { try sut.find(button: "Paste") }
    }

    @Test func addSendsLinkAndTitleToTheEngineAndClearsBothFields() throws {
        let h = Books.harness([])
        let state = AddRowState(link: "  example.com/post ", title: "Essay")
        try state.inspect(h).find(button: "Add").tap()
        let list = h.store.prefs.reading.list
        #expect(list.map(\.url.absoluteString) == ["https://example.com/post"])
        #expect(list.map(\.title) == ["Essay"])
        #expect(state.link.isEmpty)
        #expect(state.title.isEmpty)
        #expect(state.problem == nil)
    }

    @Test func addWithoutATitleKeepsTheTitleEmpty() throws {
        let h = Books.harness([Books.alpha])
        let state = AddRowState(link: "https://beta.com/post")
        try state.inspect(h).find(button: "Add").tap()
        #expect(h.engine.data.prefs.reading.list.map(\.url.absoluteString) == ["https://alpha.com/post", "https://beta.com/post"])
        #expect(h.engine.data.prefs.reading.list.last?.title == "")
    }

    @Test(arguments: ["Paste a link", "Title (optional)"])
    func returnInEitherFieldAdds(_ placeholder: String) throws {
        let h = Books.harness([])
        let state = AddRowState(link: "https://example.com/a", title: "A")
        try AddRowState.field(state.inspect(h), placeholder).callOnSubmit()
        #expect(h.engine.data.prefs.reading.list.map(\.url.absoluteString) == ["https://example.com/a"])
        #expect(state.link.isEmpty)
        #expect(state.title.isEmpty)
    }

    private static func refusedLink(_ reason: ReadingAddResult) -> String {
        switch reason {
        case .unsupportedScheme: "ftp://example.com/a"
        case .missingHost: "https://"
        case .tooLong: "https://example.com/" + String(repeating: "x", count: Limits.readingURLMax)
        default: "https://alpha.com/post"
        }
    }

    @Test(arguments: [ReadingAddResult.unsupportedScheme, .missingHost, .tooLong, .duplicate])
    func aRefusedAddKeepsTheTextAndRecordsTheReason(_ reason: ReadingAddResult) throws {
        let h = Books.harness([Books.alpha])
        let link = Self.refusedLink(reason)
        let state = AddRowState(link: link, title: "Mine")
        try state.inspect(h).find(button: "Add").tap()
        #expect(state.problem == reason)
        #expect(state.link == link)
        #expect(state.title == "Mine")
        #expect(h.engine.data.prefs.reading.list == [Books.alpha])
    }

    @Test func aFullListRefusesWithFull() throws {
        let many = (0 ..< Limits.readingListMax).map { Books.unread("T\($0)", host: "u\($0).com") }
        let h = Books.harness(many)
        let state = AddRowState(link: "https://new.com/a")
        try state.inspect(h).find(button: "Add").tap()
        #expect(state.problem == .full)
        #expect(state.link == "https://new.com/a")
        #expect(h.engine.data.prefs.reading.list == many)
    }

    @Test(arguments: [
        (ReadingAddResult.unsupportedScheme, "Only web links and files."),
        (.missingHost, "That does not look like a link."),
        (.tooLong, "That link is too long."),
        (.duplicate, "That link is already on your list."),
        (.full, "Your list is full. Read one first.")
    ])
    func eachReasonShowsItsLine(_ reason: ReadingAddResult, _ line: String) throws {
        let sut = try AddRowState(link: "x", problem: reason).inspect(Books.harness([]))
        #expect(throws: Never.self) { try sut.find(text: line) }
    }

    @Test func noReasonShowsNoLine() throws {
        let sut = try AddRowState(link: "x").inspect(Books.harness([]))
        #expect(throws: Never.self) { try sut.find(button: "Add") }
        for line in [
            "Only web links and files.",
            "That does not look like a link.",
            "That link is too long.",
            "That link is already on your list.",
            "Your list is full. Read one first."
        ] {
            #expect(Find.lacks(sut, text: line))
        }
    }

    @Test func editingTheLinkClearsTheLine() throws {
        let state = AddRowState(link: "ftp://a", problem: .unsupportedScheme)
        try AddRowState.field(state.inspect(Books.harness([])), "Paste a link").setInput("https://a.com")
        #expect(state.link == "https://a.com")
        #expect(state.problem == nil)
    }

    @Test func pasteFillsTheLinkFieldFromTheClipboard() throws {
        let state = AddRowState(link: "old", title: "Keep", clipboard: "https://pasted.com/a")
        let h = Books.harness([])
        try state.inspect(h).find(button: "Paste").tap()
        #expect(state.link == "https://pasted.com/a")
        #expect(state.title == "Keep")
        #expect(h.engine.data.prefs.reading.list.isEmpty)
    }

    @Test func pasteClearsTheProblemLine() throws {
        let state = AddRowState(link: "ftp://a", problem: .unsupportedScheme, clipboard: "https://pasted.com/a")
        try state.inspect(Books.harness([])).find(button: "Paste").tap()
        #expect(state.link == "https://pasted.com/a")
        #expect(state.problem == nil)
    }

    @Test func pasteWithNoTextLeavesTheLinkAlone() throws {
        let state = AddRowState(link: "old", clipboard: nil)
        try state.inspect(Books.harness([])).find(button: "Paste").tap()
        #expect(state.link == "old")
    }
}
