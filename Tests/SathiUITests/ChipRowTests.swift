@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Chip row")
struct ChipRowTests {
    private func row(selected: Set<Int> = [], onTap: @escaping (Int) -> Void = { _ in }) -> ChipRow<Int> {
        ChipRow(
            options: [15, 30, 45],
            accent: Night.water,
            isSelected: { selected.contains($0) },
            onTap: onTap,
            label: { "\($0) min" }
        )
    }

    @Test func showsOneButtonPerOptionInOrder() throws {
        let buttons = try row().inspect().findAll(ViewType.Button.self)
        let titles = try buttons.map { try $0.labelView().find(ViewType.Text.self).string() }
        #expect(titles == ["15 min", "30 min", "45 min"])
    }

    @Test func tapCallsOnTapWithTheValueOnce() throws {
        let taps = Box<[Int]>([])
        try row(onTap: { taps.value.append($0) }).inspect().find(button: "30 min").tap()
        #expect(taps.value == [30])
    }

    @Test func onlySelectedChipsHaveTheSelectedTrait() throws {
        let sut = try row(selected: [15, 45]).inspect()
        #expect(try A11y.isSelected(sut.find(button: "15 min")))
        #expect(try !A11y.isSelected(sut.find(button: "30 min")))
        #expect(try A11y.isSelected(sut.find(button: "45 min")))
    }

    @Test func noChipIsSelectedWhenNothingIsSelected() throws {
        let sut = try row().inspect()
        for title in ["15 min", "30 min", "45 min"] {
            #expect(try !A11y.isSelected(sut.find(button: title)))
        }
    }
}
