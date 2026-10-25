import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Lock view")
struct LockViewTests {
    @Test(arguments: [
        (HabitID.water, "Fota is drying up. Go get some water."),
        (HabitID.reading, "Boi has waited long enough. Get your book."),
        (HabitID.meditation, "Shanti is waiting. Take a slow breath.")
    ])
    func lockShowsTheHabitHeadline(_ id: HabitID, _ headline: String) throws {
        let h = EngineHarness()
        let sut = LockView(id: id).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: headline) != nil)
    }

    @Test(arguments: HabitID.allCases)
    func lockShowsTheReasonAndTheHoldHint(_ id: HabitID) throws {
        let h = EngineHarness()
        let sut = LockView(id: id).environmentObject(h.engine)
        #expect(try sut.inspect().find(text: "SNOOZED TWICE · SCREEN PAUSED") != nil)
        #expect(try sut.inspect().find(text: "Press and hold.") != nil)
    }
}
