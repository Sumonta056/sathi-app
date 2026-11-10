import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker categories card")
struct TrackerCategoriesCardTests {
    private func card(_ h: EngineHarness) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TrackerCategoriesCard(), h).inspect()
    }

    @Test func listsEveryCategory() throws {
        let sut = try card(EngineHarness())
        let fields = sut.findAll(ViewType.TextField.self)
        #expect(fields.count == ActivityCategory.defaults.count)
    }

    @Test func removeDeletesFromPrefsOnly() throws {
        let h = EngineHarness()
        let name = ActivityCategory.defaults[0].name
        try Find.button(card(h), label: Copywriter.trackerRemoveCategory(name)).tap()
        #expect(!h.store.prefs.tracker.categories.contains { $0.name == name })
    }

    @Test func addButtonAddsACategory() throws {
        let h = EngineHarness { $0.prefs.tracker.categories = [ActivityCategory(name: "Coding", colorHex: 0x4CC3F5)] }
        try card(h).find(button: Copywriter.trackerAddCategory).tap()
        #expect(h.engine.activityCategories.count == 2)
    }

    @Test func fullListHidesAddAndShowsLimit() throws {
        let many = (0 ..< Limits.categoryMax).map { ActivityCategory(name: "C\($0)", colorHex: 0x4CC3F5) }
        let h = EngineHarness { $0.prefs.tracker.categories = many }
        let sut = try card(h)
        _ = try sut.find(text: Copywriter.trackerCategoriesFull)
        #expect(throws: (any Error).self) { try sut.find(button: Copywriter.trackerAddCategory) }
    }

    @Test func commitRenameRenames() {
        let h = EngineHarness()
        let old = ActivityCategory.defaults[0].name
        #expect(TrackerCategoryChip.commit(rename: "Deep work", from: old, in: h.engine))
        #expect(h.engine.activityCategories[0].name == "Deep work")
    }

    @Test func commitRenameRejectsDuplicate() {
        let h = EngineHarness()
        let names = ActivityCategory.defaults.map(\.name)
        #expect(!TrackerCategoryChip.commit(rename: names[1], from: names[0], in: h.engine))
        #expect(h.engine.activityCategories.map(\.name) == names)
    }

    @Test func swatchRecolors() {
        let h = EngineHarness()
        let name = ActivityCategory.defaults[0].name
        let hex = ActivityCategory.palette[5]
        TrackerCategoryChip.recolor(name, to: hex, in: h.engine)
        #expect(h.engine.activityCategories[0].colorHex == hex)
    }

    @Test func deletedCategoryStaysOnOldActivities() throws {
        let name = ActivityCategory.defaults[0].name
        let start = day(2026, 3, 4, 9)
        let old = Activity(kind: .work, text: "Fix bug", category: name, start: start, end: start.addingTimeInterval(1800))
        let store = InMemoryActivityStore(activities: [old])
        let h = EngineHarness(activities: store)
        try Find.button(card(h), label: Copywriter.trackerRemoveCategory(name)).tap()
        #expect(!h.engine.activityCategories.contains { $0.name == name })
        #expect(store.all.first?.category == name)
    }

    @Test func deleteClearsCalendarMappingsToIt() {
        let h = EngineHarness {
            $0.prefs.tracker.categoryByCalendar = ["work": "Review", "home": "Learning"]
            $0.prefs.tracker.eventCategoryByTitle = ["Standup": "Review"]
        }
        h.engine.removeTrackerCategory("Review")
        #expect(h.engine.data.prefs.tracker.categoryByCalendar == ["home": "Learning"])
        #expect(h.engine.data.prefs.tracker.eventCategoryByTitle.isEmpty)
    }

    @Test func renameRewritesCalendarMappings() {
        let h = EngineHarness {
            $0.prefs.tracker.categoryByCalendar = ["work": "Review", "home": "Learning"]
            $0.prefs.tracker.eventCategoryByTitle = ["Standup": "Review"]
        }
        #expect(h.engine.renameTrackerCategory("Review", to: "Code review"))
        #expect(h.engine.data.prefs.tracker.categoryByCalendar == ["work": "Code review", "home": "Learning"])
        #expect(h.engine.data.prefs.tracker.eventCategoryByTitle == ["Standup": "Code review"])
    }

    @Test func failedRenameKeepsMappings() {
        let h = EngineHarness { $0.prefs.tracker.categoryByCalendar = ["work": "Review"] }
        #expect(!h.engine.renameTrackerCategory("Review", to: "Coding"))
        #expect(h.engine.data.prefs.tracker.categoryByCalendar == ["work": "Review"])
    }
}
