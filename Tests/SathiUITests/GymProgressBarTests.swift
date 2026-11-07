import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Gym progress bar")
struct GymProgressBarTests {
    private func progress(done: Double, sessions: Int = 4, minutes: Int = 5) -> GymProgress {
        var prefs = GymPrefs()
        prefs.sessionsPerDay = sessions
        prefs.sessionMinutes = minutes
        return GymProgress(prefs: prefs, doneMinutes: done)
    }

    @Test func barShowsDoneOfGoalAndTheCurrentSession() throws {
        let sut = try GymProgressBar(progress: progress(done: 10)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "10 of 20 min today · session 3 of 4") }
    }

    @Test func aFullDayStaysOnTheLastSession() throws {
        let sut = try GymProgressBar(progress: progress(done: 25)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "20 of 20 min today · session 4 of 4") }
    }

    @Test(arguments: [(0.0, 0), (4.0, 0), (5.0, 1), (12.0, 2), (20.0, 4), (30.0, 4)])
    func partsFillPerWholeSession(_ done: Double, _ filled: Int) {
        let p = progress(done: done)
        for index in 0 ..< 4 {
            #expect(GymProgressBar.isFilled(index, p) == (index < filled))
        }
    }

    @Test func partsFollowTheSessionCount() {
        let p = progress(done: 20, sessions: 6, minutes: 10)
        #expect(GymProgressBar.isFilled(1, p))
        #expect(!GymProgressBar.isFilled(2, p))
        #expect(!GymProgressBar.isFilled(5, p))
    }
}
