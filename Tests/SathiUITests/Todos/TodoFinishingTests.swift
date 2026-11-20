import Foundation
import SathiTestSupport
@testable import SathiUI
import Testing

@MainActor
@Suite("Todo finishing")
struct TodoFinishingTests {
    @Test func aTickChecksTheRowAndWritesNothingYet() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        #expect(sut.phase("a") == .checked)
        #expect(sut.phase("b") == nil)
        #expect(gate.delays == [1.0])
        #expect(gate.writes.isEmpty)
    }

    @Test func aSecondTickDuringTheHoldUndoesThenNeverWrites() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        sut.tick("a")
        #expect(sut.phase("a") == nil)
        gate.release()
        await gate.settle()
        gate.release()
        await gate.settle()
        #expect(sut.phase("a") == nil)
        #expect(gate.writes.isEmpty)
    }

    @Test func tickingAgainAfterAnUndoStartsAFreshHold() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        sut.tick("a")
        sut.tick("a")
        #expect(sut.phase("a") == .checked)
        await waitUntil { gate.waiting == 2 }
        gate.release()
        await gate.settle()
        #expect(sut.phase("a") == .leaving)
        gate.release()
        await waitUntil { !gate.writes.isEmpty }
        await gate.settle()
        #expect(gate.writes == ["a"])
    }

    @Test func afterTheHoldTheRowFoldsThenWritesExactlyOnce() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        gate.release()
        await waitUntil { sut.phase("a") == .leaving && gate.waiting == 1 }
        #expect(sut.phase("a") == .leaving)
        #expect(gate.delays == [1.0, 0.26])
        #expect(gate.writes.isEmpty)
        gate.release()
        await waitUntil { !gate.writes.isEmpty }
        await gate.settle()
        #expect(gate.writes == ["a"])
        #expect(sut.phase("a") == .leaving)
        sut.settle()
        #expect(sut.phase("a") == nil)
    }

    @Test func flushDuringTheHoldWritesOnceThenNeverAgain() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        sut.flush()
        #expect(gate.writes == ["a"])
        gate.release()
        await gate.settle()
        gate.release()
        await gate.settle()
        #expect(gate.writes == ["a"])
        #expect(sut.phase("a") == .leaving)
        sut.settle()
        #expect(sut.phase("a") == nil)
    }

    @Test func flushWritesEveryPendingRowAtOnce() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        sut.tick("b")
        await waitUntil { gate.waiting == 2 }
        sut.flush()
        #expect(Set(gate.writes) == ["a", "b"])
        #expect(gate.writes.count == 2)
        gate.release()
        await gate.settle()
        gate.release()
        await gate.settle()
        #expect(gate.writes.count == 2)
    }

    @Test func flushDuringTheFoldWritesOnce() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        await waitUntil { gate.waiting == 1 }
        gate.release()
        await waitUntil { sut.phase("a") == .leaving && gate.waiting == 1 }
        sut.flush()
        gate.release()
        await gate.settle()
        #expect(gate.writes == ["a"])
    }

    @Test func flushWithNothingPendingWritesNothing() {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.flush()
        #expect(gate.writes.isEmpty)
    }

    @Test func eachRowHasItsOwnHold() async {
        let gate = TodoFinishingGate()
        let sut = gate.finishing()
        sut.tick("a")
        sut.tick("b")
        await waitUntil { gate.waiting == 2 }
        sut.tick("a")
        #expect(sut.phase("a") == nil)
        #expect(sut.phase("b") == .checked)
        gate.release()
        await gate.settle()
        gate.release()
        await waitUntil { !gate.writes.isEmpty }
        await gate.settle()
        #expect(gate.writes == ["b"])
    }
}
