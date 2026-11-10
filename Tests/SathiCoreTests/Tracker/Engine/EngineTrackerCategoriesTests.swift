import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker categories")
struct EngineTrackerCategoriesTests {
    private func harness() -> EngineHarness {
        EngineHarness {
            $0.prefs.tracker.categoryByCalendar = ["work": "Review", "home": "Learning"]
            $0.prefs.tracker.eventCategoryByTitle = ["Standup": "Review", "Book": "Learning"]
        }
    }

    @Test func renameRewritesCalendarAndTitleMappings() {
        let h = harness()
        #expect(h.engine.renameActivityCategory("Review", to: "Code review"))
        #expect(h.engine.data.prefs.tracker.categoryByCalendar == ["work": "Code review", "home": "Learning"])
        #expect(h.engine.data.prefs.tracker.eventCategoryByTitle == ["Standup": "Code review", "Book": "Learning"])
    }

    @Test func aRefusedRenameKeepsTheMappings() {
        let h = harness()
        #expect(!h.engine.renameActivityCategory("Review", to: "Coding"))
        #expect(h.engine.data.prefs.tracker.categoryByCalendar["work"] == "Review")
        #expect(h.engine.data.prefs.tracker.eventCategoryByTitle["Standup"] == "Review")
    }

    @Test func deleteClearsTheMappingsToIt() {
        let h = harness()
        h.engine.deleteActivityCategory("Review")
        #expect(h.engine.data.prefs.tracker.categoryByCalendar == ["home": "Learning"])
        #expect(h.engine.data.prefs.tracker.eventCategoryByTitle == ["Book": "Learning"])
        #expect(!h.engine.activityCategories.contains { $0.name == "Review" })
    }
}
