import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Close button off")
struct CloseButtonOffTests {
    @Test(arguments: ReminderSurface.allCases)
    func closeIsHiddenWhenTheSwitchIsOff(_ s: ReminderSurface) throws {
        let h = s.harness { $0.prefs.setShowsCloseButton(s.id, false) }
        #expect(h.engine.phase(s.id) == .bubble(.nudge))
        #expect(try !hasDismiss(s.inspect(h, .nudge)))
    }

    @Test(arguments: ReminderSurface.allCases)
    func offForAnotherHabitKeepsThisClose(_ s: ReminderSurface) throws {
        let h = s.harness {
            for other in HabitID.allCases where other != s.id {
                $0.prefs.setShowsCloseButton(other, false)
            }
        }
        #expect(try hasDismiss(s.inspect(h, .nudge)))
    }

    @Test(arguments: HabitID.allCases)
    func tappingTheSwitchFlipsThePref(_ id: HabitID) throws {
        let h = allOnHarness()
        try closeSwitch(settingsTab(id, h)).tap()
        #expect(!h.engine.data.prefs.showsCloseButton(id))
        #expect(!h.store.prefs.showsCloseButton(id))
        for other in HabitID.allCases where other != id {
            #expect(h.engine.data.prefs.showsCloseButton(other))
        }
        try closeSwitch(settingsTab(id, h)).tap()
        #expect(h.engine.data.prefs.showsCloseButton(id))
    }

    @Test(arguments: HabitID.allCases)
    func switchShowsOffWhenStoredOff(_ id: HabitID) throws {
        let sut = try settingsTab(id, allOnHarness { $0.prefs.setShowsCloseButton(id, false) })
        #expect(try !A11y.isSelected(closeSwitch(sut)))
    }
}
