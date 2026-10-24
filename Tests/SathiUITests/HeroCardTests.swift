import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Hero card")
struct HeroCardTests {
    private func hero(_ box: Box<Bool>) -> HeroCard<Text> {
        HeroCard(
            habit: .water,
            eyebrow: "FOTA",
            title: "Water reminders",
            hint: "Every 2 hours",
            isOn: box.binding,
            switchLabel: "Remind me to drink water"
        ) {
            Text("Buddy")
        }
    }

    @Test func showsBuddyEyebrowTitleAndHint() throws {
        let sut = try hero(Box(true)).inspect()
        for text in ["Buddy", "FOTA", "Water reminders", "Every 2 hours"] {
            #expect(try sut.find(text: text).string() == text)
        }
    }

    @Test func holdsABuddySwitchWithTheSwitchLabel() throws {
        let sut = try hero(Box(true)).inspect().find(BuddySwitch.self)
        #expect(throws: Never.self) { try sut.find(viewWithAccessibilityLabel: "Remind me to drink water") }
    }

    @Test func switchTapFlipsIsOn() throws {
        let box = Box(true)
        try hero(box).inspect().find(BuddySwitch.self).find(ViewType.Button.self).tap()
        #expect(box.value == false)
    }
}
