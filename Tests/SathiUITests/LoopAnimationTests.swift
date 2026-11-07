import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Loop animations")
struct LoopAnimationTests {
    private let tolerance = 0.0001

    private func near(_ a: Double, _ b: Double) -> Bool { abs(a - b) < tolerance }

    @Test func bobStartsAtRest() {
        #expect(near(Double(BobbingBuddy.offset(at: 0)), 0))
    }

    @Test func bobPeaksAfterOneDuration() {
        #expect(near(Double(BobbingBuddy.offset(at: UIMetrics.bobDuration)), -Double(UIMetrics.bobHeight)))
    }

    @Test func bobReturnsAfterTwoDurations() {
        #expect(near(Double(BobbingBuddy.offset(at: 2 * UIMetrics.bobDuration)), 0))
    }

    @Test func sparkStartsHiddenAndSmall() {
        let p = SparkBurst.phase(at: 0)
        #expect(near(p.opacity, 0))
        #expect(near(Double(p.scale), 0.4))
    }

    @Test func sparkIsBrightestAtFortyPercent() {
        #expect(near(SparkBurst.phase(at: 0.4 * UIMetrics.sparkDuration).opacity, 1))
    }

    @Test func sparkFadesOutBigAtTheEnd() {
        let p = SparkBurst.phase(at: UIMetrics.sparkDuration - 0.001)
        #expect(p.opacity < 0.01)
        #expect(abs(Double(p.scale) - 1.4) < 0.01)
    }

    @Test(arguments: [(5.0, 1.0), (2.5, 0.5), (-1.0, 0.0)])
    func ignoreBarFraction(_ minutesAhead: Double, _ expected: Double) {
        let now = day(2026, 3, 4, 10)
        let deadline = now.addingTimeInterval(minutesAhead * Timing.minute)
        #expect(near(IgnoreBar.fraction(deadline: deadline, now: now, total: 5 * Timing.minute), expected))
    }

    @Test func ignoreBarWithNoTotalIsEmpty() {
        let now = day(2026, 3, 4, 10)
        #expect(IgnoreBar.fraction(deadline: now.addingTimeInterval(Timing.minute), now: now, total: 0) == 0)
    }
}
