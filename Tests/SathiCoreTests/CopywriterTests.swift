import SathiCore
import Testing

@Suite("Copywriter")
struct CopywriterTests {
    @Test func usesNameWhenGiven() {
        let titles = (0 ..< 60).map { _ in Copywriter.pick(.water, .nudge, name: "Mridul").title }
        #expect(titles.contains { $0.contains("Mridul") })
        #expect(!titles.contains { $0.contains("friend") })
    }

    @Test func fallsBackToFriendForBlankName() {
        #expect(Copywriter.displayName("   ") == "friend")
        let titles = (0 ..< 60).map { _ in Copywriter.pick(.reading, .nudge, name: "   ").title }
        #expect(titles.contains { $0.contains("friend") })
    }

    @Test(arguments: HabitID.allCases)
    func everyLevelHasCopy(_ id: HabitID) {
        for level in [Level.nudge, .persist] {
            let copy = Copywriter.pick(id, level, name: "A")
            #expect(!copy.title.isEmpty)
            #expect(!copy.body.isEmpty)
        }
    }

    @Test(arguments: HabitID.allCases)
    func celebrationTitleIsNeverEmpty(_ id: HabitID) {
        #expect(!Copywriter.celebrationTitle(id).isEmpty)
    }
}
