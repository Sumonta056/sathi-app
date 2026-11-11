import SathiCore
import Testing

@Suite("Range change")
struct RangeChangeTests {
    @Test func higherIsUpByTheDifference() {
        #expect(RangeChange(current: 9, previous: 3, hasData: true) == .up(6))
    }

    @Test func lowerIsDownByTheDifference() {
        #expect(RangeChange(current: 2, previous: 3, hasData: true) == .down(1))
    }

    @Test func equalIsSame() {
        #expect(RangeChange(current: 3, previous: 3, hasData: true) == .same)
    }

    @Test func noDataIsNone() {
        #expect(RangeChange(current: 0, previous: 0, hasData: false) == .none)
    }
}
