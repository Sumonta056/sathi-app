import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("To-dos narrow row and add field")
struct TodoNarrowRowTests {
    @Test func theDueChipLeavesTheFieldRowOnlyWhenNarrow() {
        #expect(TodoAddField.chipOnFieldRow(NarrowSupport.wide))
        #expect(TodoAddField.chipOnFieldRow(NarrowSupport.drawerOnly))
        #expect(!TodoAddField.chipOnFieldRow(NarrowSupport.narrow))
    }

    @Test func theRepeatsWordHidesOnlyWhenNarrow() {
        #expect(TodoRowMeta.showsRepeatsWord(NarrowSupport.wide))
        #expect(!TodoRowMeta.showsRepeatsWord(NarrowSupport.narrow))
    }

    @Test func aDoneRowCarriesNoLink() throws {
        let link = try #require(URL(string: "https://console.typesafe.ai/homen"))
        let parts: [TodoTitlePart] = [.link(label: "console.typesafe.ai/homen", url: link), .text(" : Try jev")]
        let title = TodoRow.attributedTitle(parts, linked: false)
        #expect(String(title.characters) == "console.typesafe.ai/homen : Try jev")
        #expect(title.runs.allSatisfy { $0.link == nil })
    }

    @Test func theRowActionIsAVerb() {
        #expect(Copywriter.todoEdit == "Edit")
    }
}
