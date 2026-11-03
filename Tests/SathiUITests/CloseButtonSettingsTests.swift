import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Close button settings")
struct CloseButtonSettingsTests {
    @Test(arguments: HabitID.allCases)
    func everyTabHasTheCloseButtonSwitch(_ id: HabitID) throws {
        let sut = try settingsTab(id, allOnHarness())
        #expect(throws: Never.self) { try sut.find(text: "Show a close button") }
        #expect(throws: Never.self) { try closeSwitch(sut) }
    }

    @Test(arguments: HabitID.allCases)
    func switchIsOnByDefault(_ id: HabitID) throws {
        let sut = try settingsTab(id, allOnHarness())
        #expect(try A11y.isSelected(closeSwitch(sut)))
    }
}
