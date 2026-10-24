import SathiCore
import Testing

@Suite("EscalationPolicy")
struct EscalationPolicyTests {
    @Test(arguments: [0, 1, 5])
    func friendlyAlwaysNudges(_ snoozes: Int) {
        #expect(EscalationPolicy.presentation(for: .friendly, snoozes: snoozes) == .bubble(.nudge))
    }

    @Test func persistentPersistsAfterFirstSnooze() {
        #expect(EscalationPolicy.presentation(for: .persistent, snoozes: 0) == .bubble(.nudge))
        #expect(EscalationPolicy.presentation(for: .persistent, snoozes: 1) == .bubble(.persist))
        #expect(EscalationPolicy.presentation(for: .persistent, snoozes: 4) == .bubble(.persist))
    }

    @Test func strictLocksAfterTwoSnoozes() {
        #expect(EscalationPolicy.presentation(for: .strict, snoozes: 0) == .bubble(.nudge))
        #expect(EscalationPolicy.presentation(for: .strict, snoozes: 1) == .bubble(.persist))
        #expect(EscalationPolicy.presentation(for: .strict, snoozes: 2) == .lock)
    }

    @Test func lockIsNextOnlyForStrictAfterASnooze() {
        #expect(!EscalationPolicy.lockIsNext(.strict, snoozes: 0))
        #expect(EscalationPolicy.lockIsNext(.strict, snoozes: 1))
        #expect(!EscalationPolicy.lockIsNext(.persistent, snoozes: 3))
    }
}
