import Foundation
import SathiCore
@testable import SathiUI
import Testing

@MainActor
@Suite("Activity merge check memo")
struct ActivityMergeCheckMemoTests {
    @Test func aChangeOfTheHeldRowsChecksAgain() {
        let memo = ActivityMergeCheckMemo()
        let id = ActivityID()
        var calls = 0
        let make: (Set<ActivityID>) -> ManualMergeCheck = { _ in
            calls += 1
            return .blocked(.tooFew)
        }
        _ = memo.value([id], rows: [], held: [id], make: make)
        _ = memo.value([id], rows: [], held: [id], make: make)
        #expect(calls == 1)
        _ = memo.value([id], rows: [], held: [], make: make)
        #expect(calls == 2)
    }
}
