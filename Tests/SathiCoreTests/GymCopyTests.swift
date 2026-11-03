import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Gym copy")
struct GymCopyTests {
    @Test func gymNamesTheBuddyShokti() {
        #expect(HabitID.gym.name == "Gym")
        #expect(HabitID.gym.buddy == "Shokti")
        #expect(HabitID.gym.rawValue == "gym")
    }

    @Test func storedStrictGymStaysStrict() {
        var p = Prefs()
        p.gym.strictness = .strict
        #expect(p.strictness(.gym) == .strict)
    }

    @Test func inviteHintNamesWorkoutAndMinutes() {
        #expect(Copywriter.gymInviteHint(GymWorkout(name: "Short walk", minutes: 5)) == "Short walk · 5 min")
    }

    @Test(arguments: [Level.nudge, .persist])
    func gymCopyHasNudgeAndPersistLines(_ level: Level) {
        let copies = (0 ..< 80).map { _ in Copywriter.pick(.gym, level, name: "Asha") }
        #expect(Set(copies.map(\.title)).count >= 2)
        #expect(copies.allSatisfy { !$0.title.isEmpty && !$0.body.isEmpty })
    }

    @Test func gymComesBackNoteNamesShokti() {
        #expect(Copywriter.comesBack(.gym, at: day(2026, 3, 4, 11), calendar: .current).hasPrefix("Shokti comes back at"))
    }

    @Test func gymTimerLineIsOneKindLine() {
        #expect(Copywriter.gymTimerLine() == "Go at your own pace. Every move counts.")
    }
}
