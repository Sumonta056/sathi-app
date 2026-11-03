import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Habit list")
struct HabitListTests {
    private static let actions: [(HabitID, String)] = [
        (.water, "+1 glass"), (.reading, "Read now"), (.meditation, "Breathe"), (.gym, "Move")
    ]

    @Test func actionSizeConstants() {
        #expect(UIMetrics.menuActionWidth == 84)
        #expect(UIMetrics.menuActionHeight == 30)
    }

    @Test(arguments: actions)
    func actionButtonHasTheSharedWidth(_ id: HabitID, _ title: String) throws {
        let card = try hosted(HabitCard(id: id), Glance.harness()).inspect()
        let button = try MenuFind.control(card, title)
        #expect(Glance.fixedWidth(button) == UIMetrics.menuActionWidth)
    }

    @Test func listHoldsOneRowPerEnabledHabitInOrder() throws {
        let h = EngineHarness { $0.prefs.gym.enabled = true }
        let sut = try hosted(HabitList(), h).inspect()
        #expect(try sut.findAll(HabitCard.self).map { try $0.actualView().id } == [.water, .reading, .gym])
    }

    @Test func panelHoldsOneHabitListWithEveryCard() throws {
        let sut = try Glance.panel(Glance.harness())
        let list = try sut.find(HabitList.self)
        #expect(sut.findAll(HabitList.self).count == 1)
        #expect(try list.findAll(HabitCard.self).map { try $0.actualView().id } == HabitID.allCases)
    }
}
