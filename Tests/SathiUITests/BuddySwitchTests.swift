@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Buddy switch")
struct BuddySwitchTests {
    private func toggle(_ box: Box<Bool>) -> BuddySwitch {
        BuddySwitch(isOn: box.binding, accent: Night.water, label: "Remind me to drink water")
    }

    @Test func tapFlipsTheBindingOnThenOff() throws {
        let box = Box(false)
        try toggle(box).inspect().find(ViewType.Button.self).tap()
        #expect(box.value == true)
        try toggle(box).inspect().find(ViewType.Button.self).tap()
        #expect(box.value == false)
    }

    @Test func hasTheGivenAccessibilityLabel() throws {
        let sut = try toggle(Box(false)).inspect()
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "Remind me to drink water") }
    }

    @Test(arguments: [(true, "On"), (false, "Off")])
    func accessibilityValueFollowsState(_ isOn: Bool, _ expected: String) throws {
        let sut = try toggle(Box(isOn)).inspect()
        let other = isOn ? "Off" : "On"
        #expect(throws: Never.self) { try sut.find(where: { try $0.accessibilityValue().string() == expected }) }
        #expect(sut.findAll(where: { try $0.accessibilityValue().string() == other }).isEmpty)
    }

    @Test func selectedTraitOnlyWhenOn() throws {
        #expect(try A11y.isSelected(toggle(Box(true)).inspect().find(ViewType.Button.self)))
        #expect(try !A11y.isSelected(toggle(Box(false)).inspect().find(ViewType.Button.self)))
    }
}
