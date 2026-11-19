import CoreGraphics
@testable import SathiUI
import Testing

@Suite("Weighted row")
struct WeightedRowTests {
    @Test("splits the width after the gap by the weights")
    func splitsByWeight() {
        let widths = WeightedRow.widths(total: 1000, gap: 14, weights: [1.7, 1])
        #expect(abs(widths[0] - 1.7 * 986 / 2.7) < 0.001)
        #expect(abs(widths[1] - 986 / 2.7) < 0.001)
        #expect(abs(widths.reduce(0, +) + 14 - 1000) < 0.001)
    }

    @Test("never returns negative widths")
    func clampsNegative() {
        let widths = WeightedRow.widths(total: 5, gap: 14, weights: [1.7, 1])
        #expect(widths.allSatisfy { $0 >= 0 })
    }
}
