import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Calendar menu")
struct CalendarMenuTests {
    private func menu(_ h: EngineHarness, _ picked: Picked<String>) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(CalendarMenu(selection: picked.binding), h).inspect()
    }

    @Test func showsTheSelectedCalendarTitleAndAccount() throws {
        let sut = try menu(Block.harness(), Picked("home"))
        let label = try MenuFind.texts(sut.find(ViewType.Menu.self).labelView())
        #expect(label.contains { $0.contains("Home") })
        #expect(label.contains { $0.contains("iCloud") })
    }

    @Test func listsEveryChoiceGroupedByAccount() throws {
        let sut = try menu(Block.harness(), Picked("work"))
        let texts = try MenuFind.texts(sut.find(ViewType.Menu.self))
        #expect(texts.contains("Gmail Work"))
        #expect(texts.contains("Home"))
        #expect(texts.contains("Gmail"))
        #expect(texts.contains("iCloud"))
    }

    @Test func choosingARowSetsTheSelection() throws {
        let picked = Picked("work")
        let sut = try menu(Block.harness(), picked)
        try sut.find(ViewType.Menu.self).find(button: "Home").tap()
        #expect(picked.value == "home")
    }
}
