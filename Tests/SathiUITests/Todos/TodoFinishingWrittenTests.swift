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
        sut.settle()
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
}
