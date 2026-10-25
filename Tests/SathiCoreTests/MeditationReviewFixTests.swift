import Foundation
import SathiCore
import SathiTestSupport
import Testing

@Suite("Meditation review fixes")
struct MeditationReviewFixTests {
    @Test func lastDoneIsTheLatestDoneEventInAnyOrder() {
        var data = Persisted()
        data.events = [
            .done(.meditation, 5, at: day(2026, 3, 4, 8, 5)),
            .done(.meditation, 5, at: day(2026, 3, 3, 21, 35)),
            .done(.meditation, 5, at: day(2026, 3, 2, 8, 5))
        ]
        #expect(data.lastDone(.meditation) == day(2026, 3, 4, 8, 5))
    }

    @Test func savedPrefsNoLongerWriteSlots() throws {
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MeditationPrefs())) as? [String: Any]
        #expect(object?["slots"] == nil)
        #expect(object?["dailyGoalMinutes"] as? Int == 10)
    }
}
