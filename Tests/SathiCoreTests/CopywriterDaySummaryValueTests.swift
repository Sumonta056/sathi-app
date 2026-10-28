import SathiCore
import Testing

@Suite("Copywriter day summary value")
struct CopywriterDaySummaryValueTests {
    @Test(arguments: [
        (HabitID.water, 6.0, 8.0, "6", "of 8 glasses"),
        (.water, 2.5, 8, "2½", "of 8 glasses"),
        (.water, 9, 8, "9", "of 8 glasses"),
        (.reading, 5, 15, "5", "of 15 min"),
        (.reading, 20, 15, "15", "of 15 min"),
        (.meditation, 3, 10, "3", "of 10 min"),
        (.meditation, 12, 10, "10", "of 10 min"),
        (.gym, 2, 4, "2", "of 4 workouts"),
        (.gym, 0, 4, "0", "of 4 workouts")
    ])
    func valueUsesTheRowsOwnNumbers(_ id: HabitID, _ done: Double, _ goal: Double, _ d: String, _ rest: String) {
        #expect(Copywriter.daySummaryValue(id, done: done, goal: goal) == GoalText(done: d, rest: rest))
    }
}
