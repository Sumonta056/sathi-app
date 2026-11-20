import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Todo finishing after the write")
struct TodoFinishingWrittenTests {
    @Test func aWrittenRowStaysFoldedUntilTheNextSnapshot() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        gate.release()
        await waitUntil { sut.phase("a") == .leaving && gate.waiting == 1 }
        gate.release()
        await waitUntil { !gate.writes.isEmpty }
        await gate.settle()
        #expect(sut.phase("a") == .leaving)
        sut.flush("a")
        sut.flush()
        sut.tick("a")
        #expect(gate.writes == ["a"])
        #expect(sut.phase("a") == .leaving)
        sut.settle(open: [])
        #expect(sut.phase("a") == nil)
    }

    @Test func aTickDuringTheFoldIsIgnored() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        gate.release()
        await waitUntil { sut.phase("a") == .leaving && gate.waiting == 1 }
        sut.tick("a")
        #expect(sut.phase("a") == .leaving)
        gate.release()
        await waitUntil { !gate.writes.isEmpty }
        await gate.settle()
        #expect(gate.writes == ["a"])
    }

    private func written(_ gate: TodoFinishingGate) async -> TodoFinishing {
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        gate.release()
        await waitUntil { sut.phase("a") == .leaving && gate.waiting == 1 }
        gate.release()
        await waitUntil { !gate.writes.isEmpty }
        await gate.settle()
        return sut
    }

    @Test func aFailedWriteBringsTheRowBack() async {
        let gate = TodoFinishingGate()
        let sut = await written(gate)
        #expect(sut.phase("a") == .leaving)
        sut.fail("a")
        #expect(sut.phase("a") == nil)
    }

    @Test func failingAnIdThatWasNotWrittenChangesNothing() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        sut.fail("a")
        #expect(sut.phase("a") == .checked)
    }

    @Test func anUnrelatedSnapshotKeepsTheRowFolded() async {
        let gate = TodoFinishingGate()
        let sut = await written(gate)
        sut.settle(open: ["a", "b"])
        #expect(sut.phase("a") == .leaving)
    }

    @Test func aSnapshotWithoutTheOpenTodoClearsIt() async {
        let gate = TodoFinishingGate()
        let sut = await written(gate)
        sut.settle(open: ["b"])
        #expect(sut.phase("a") == nil)
    }
}
