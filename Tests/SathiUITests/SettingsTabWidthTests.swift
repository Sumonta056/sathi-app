import AppKit
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Settings tab width")
struct SettingsTabWidthTests {
    private static let column = UIMetrics.settingsSize.width - UIMetrics.sidebarWidth
        - UIMetrics.contentPadding.leading - UIMetrics.contentPadding.trailing

    private func width(of view: some View) -> CGFloat {
        let h = EngineHarness {
            $0.prefs.water.enabled = true
            $0.prefs.reading.enabled = true
            $0.prefs.meditation.enabled = true
            $0.prefs.gym.enabled = true
        }
        let host = NSHostingController(rootView: view.environmentObject(h.engine).environment(\.colorScheme, .dark))
        return host.sizeThatFits(in: CGSize(width: Self.column, height: .greatestFiniteMagnitude)).width
    }

    @Test(arguments: HabitID.allCases)
    func habitTabFitsTheContentColumn(id: HabitID) {
        #expect(width(of: HabitTab(id: id)) <= Self.column)
    }

    @Test func generalAndAddBuddyTabsFitTheContentColumn() {
        #expect(width(of: GeneralTab()) <= Self.column)
        #expect(width(of: AddBuddyTab()) <= Self.column)
    }

    @Test(arguments: [Limits.dailyGoalGlasses.lowerBound, Limits.dailyGoalGlasses.upperBound])
    func glassGoalRowFitsTheContentColumn(goal: Double) {
        #expect(width(of: SettingsCard { GlassGoalRow(goal: .constant(goal)) }) <= Self.column)
    }
}
