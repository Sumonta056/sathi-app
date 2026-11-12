import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Activity text sheet")
struct ActivityTextSheetTests {
    private func sheet(
        copyLabel: String = Copywriter.activitiesCopyStandup, copy: @escaping (String) -> Void = { _ in }, close: @escaping () -> Void = {}
    ) -> ActivityTextSheet {
        ActivityTextSheet(
            title: Copywriter.activitiesStandupTitle, text: "Yesterday: login bug", copyLabel: copyLabel, copy: copy, close: close
        )
    }

    @Test func showsTheTitleAndTheText() throws {
        let sut = try sheet().inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.activitiesStandupTitle) }
        #expect(throws: Never.self) { try sut.find(text: "Yesterday: login bug") }
    }

    @Test func copyGivesThatText() throws {
        var copied: String?
        let sut = try sheet(copy: { copied = $0 }).inspect()
        try Find.button(sut, holding: Copywriter.activitiesCopyStandup).tap()
        #expect(copied == "Yesterday: login bug")
    }

    @Test func closeCallsClose() throws {
        var closed = false
        let sut = try sheet(close: { closed = true }).inspect()
        try Find.button(sut, holding: Copywriter.activitiesClose).tap()
        #expect(closed)
    }

    @Test func rangeSheetUsesTheCopyLabelItIsGiven() throws {
        let sut = try sheet(copyLabel: Copywriter.activitiesCopy).inspect()
        #expect(throws: Never.self) { try Find.button(sut, holding: Copywriter.activitiesCopy) }
    }
}
