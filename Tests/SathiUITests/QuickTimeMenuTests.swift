import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Quick time menu")
struct QuickTimeMenuTests {
    private func form(_ chip: Int?, time: Date? = nil) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(QuickAddForm(chip: chip, time: time, onClose: {}), Quick.harness()).inspect()
    }

    @Test func formUsesTheTimeMenuNotTheSystemPicker() throws {
        let sut = try form(15)
        #expect(sut.findAll(TimeMenu.self).count == 1)
        #expect(sut.findAll(ViewType.DatePicker.self).isEmpty)
    }

    @Test func menuIsQuietWhileAChipIsPicked() throws {
        let menu = try form(15).find(TimeMenu.self).actualView()
        #expect(!menu.active)
        #expect(menu.accent == Night.quick)
    }

    @Test func menuIsActiveAndShowsThePickedTime() throws {
        let sut = try form(nil, time: day(2026, 3, 4, 16, 35))
        #expect(try sut.find(TimeMenu.self).actualView().active)
        #expect(throws: Never.self) { try sut.find(TimeMenu.self).find(text: Fmt.timeOfDay(16 * 60 + 35)) }
    }
}
