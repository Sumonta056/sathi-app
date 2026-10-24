import SathiCore
import Testing

@Suite("Strictness labels")
struct StrictnessLabelTests {
    @Test func rawValuesAreUnchanged() {
        #expect(Strictness.allCases.map(\.rawValue) == ["friendly", "persistent", "strict"])
    }

    @Test func titles() {
        #expect(Strictness.allCases.map(\.title) == ["Gentle", "Nudgy", "Strict"])
    }

    @Test func details() {
        #expect(Strictness.friendly.detail == "A reminder each time. It never stays on top.")
        #expect(Strictness.persistent.detail == "Stays on top, wiggles, and has no close button after a snooze.")
        #expect(Strictness.strict.detail == "Locks the screen after two snoozes.")
    }

    @Test func levels() {
        #expect(Strictness.allCases.map(\.level) == [1, 2, 3])
    }
}
