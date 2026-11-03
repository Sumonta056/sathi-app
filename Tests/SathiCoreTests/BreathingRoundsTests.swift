import Foundation
import SathiCore
import Testing

@Suite("Breathing rounds")
struct BreathingRoundsTests {
    @Test(arguments: [
        (BreathingStyle.box, 5, 19),
        (.box, 1, 4),
        (.relax, 5, 16),
        (.even, 5, 30),
        (.box, 0, 1)
    ])
    func totalRounds(_ style: BreathingStyle, _ minutes: Int, _ expected: Int) {
        #expect(BreathingPattern.totalRounds(style, minutes: minutes) == expected)
    }

    @Test(arguments: [
        (0.0, 5, 1),
        (15.9, 5, 1),
        (16, 5, 2),
        (50, 1, 4),
        (10000, 5, 19)
    ])
    func boxRound(_ elapsed: TimeInterval, _ minutes: Int, _ expected: Int) {
        #expect(BreathingPattern.round(.box, elapsed: elapsed, minutes: minutes) == expected)
    }
}
