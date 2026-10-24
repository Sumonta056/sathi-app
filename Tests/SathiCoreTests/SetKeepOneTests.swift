import SathiCore
import Testing

@Suite("Set keep one")
struct SetKeepOneTests {
    @Test func addsAMissingItem() {
        #expect(Set([1, 2]).togglingKeepingOne(3) == [1, 2, 3])
    }

    @Test func removesAPresentItem() {
        #expect(Set([1, 2]).togglingKeepingOne(2) == [1])
    }

    @Test func keepsTheLastItem() {
        #expect(Set([1]).togglingKeepingOne(1) == [1])
    }
}
