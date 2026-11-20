@testable import SathiUI
import Testing

@MainActor
@Suite("Todo tick motion")
struct TodoTickMotionTests {
    @Test func aCheckedRowPopsAndRingsWithMotionOn() {
        #expect(TodoTick.showsPop(phase: .checked, reduceMotion: false))
        #expect(TodoTick.showsRing(phase: .checked, reduceMotion: false))
    }

    @Test func reduceMotionHasNoPopOrRing() {
        #expect(!TodoTick.showsPop(phase: .checked, reduceMotion: true))
        #expect(!TodoTick.showsRing(phase: .checked, reduceMotion: true))
    }

    @Test func aRowThatIsNotFinishingDoesNotPop() {
        #expect(!TodoTick.showsPop(phase: nil, reduceMotion: false))
        #expect(!TodoTick.showsRing(phase: nil, reduceMotion: false))
    }
}
