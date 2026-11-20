@testable import SathiUI
import Testing

@MainActor
@Suite("Todo fold")
struct TodoFoldTests {
    @Test func anIdleRowHasNoFixedHeightOrClip() {
        #expect(TodoFold.fixedHeight(phase: nil, reduceMotion: false, measured: 40) == nil)
        #expect(!TodoFold.clips(phase: nil))
    }

    @Test func aCheckedRowKeepsItsHeightAndIsNotClipped() {
        #expect(TodoFold.fixedHeight(phase: .checked, reduceMotion: false, measured: 40) == 40)
        #expect(!TodoFold.clips(phase: .checked))
    }

    @Test func aLeavingRowFoldsToZeroAndClips() {
        #expect(TodoFold.fixedHeight(phase: .leaving, reduceMotion: false, measured: 40) == 0)
        #expect(TodoFold.clips(phase: .leaving))
    }

    @Test func reduceMotionKeepsTheHeightWhileLeaving() {
        #expect(TodoFold.fixedHeight(phase: .leaving, reduceMotion: true, measured: 40) == 40)
    }
}
