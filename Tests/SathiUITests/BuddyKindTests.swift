import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Buddy kind")
struct BuddyKindTests {
    @Test func gymMapsToKettlebell() {
        #expect(HabitID.gym.kind == .kettlebell)
    }

    @Test func gymBuddyRenders() throws {
        let view = BuddyView(kind: HabitID.gym.kind, mood: .happy)
        _ = try view.inspect().find(BuddyCanvas.self)
    }
}
