import SathiCore
import Testing

@Suite("Meditation copy")
struct MeditationCopyTests {
    @Test(arguments: [Level.nudge, .persist])
    func shantiHasTwoLinesPerLevel(_ level: Level) {
        let titles = Set((0 ..< 80).map { _ in Copywriter.pick(.meditation, level, name: "Asha").title })
        #expect(titles.count == 2)
    }

    @Test func shantiHasThreeCelebrationTitles() {
        let titles = Set((0 ..< 80).map { _ in Copywriter.celebrationTitle(.meditation) })
        #expect(titles.count == 3)
    }
}
