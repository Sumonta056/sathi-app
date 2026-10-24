@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Option card")
struct OptionCardTests {
    private func card(selected: Bool, action: @escaping () -> Void = {}) -> OptionCard<Text> {
        OptionCard(title: "Gentle", detail: "Only a bubble", isSelected: selected, accent: Night.water, action: action) {
            Text("Top")
        }
    }

    @Test func showsTopTitleAndDetail() throws {
        let sut = try card(selected: false).inspect()
        #expect(try sut.find(text: "Top").string() == "Top")
        #expect(try sut.find(text: "Gentle").string() == "Gentle")
        #expect(try sut.find(text: "Only a bubble").string() == "Only a bubble")
    }

    @Test func tapCallsActionOnce() throws {
        let count = Box(0)
        try card(selected: false) { count.value += 1 }.inspect().find(ViewType.Button.self).tap()
        #expect(count.value == 1)
    }

    @Test func selectedCardHasTheSelectedTrait() throws {
        #expect(try A11y.isSelected(card(selected: true).inspect().find(ViewType.Button.self)))
    }

    @Test func unselectedCardHasNoSelectedTrait() throws {
        #expect(try !A11y.isSelected(card(selected: false).inspect().find(ViewType.Button.self)))
    }
}
