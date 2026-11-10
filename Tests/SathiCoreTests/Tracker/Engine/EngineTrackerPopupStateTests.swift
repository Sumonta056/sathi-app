import Foundation
import SathiCore
import SathiTestSupport
import Testing

@MainActor
@Suite("Engine tracker popup state")
struct EngineTrackerPopupStateTests {
    private let custom = KeyShortcut(keyCode: 40, modifiers: [.control, .shift], keyName: "K")

    private func work(_ count: Int) -> [Activity] {
        (0 ..< count).map { Activity(text: "T\($0)", category: "Coding", start: wed(7, $0 * 5), end: wed(7, $0 * 5 + 2)) }
    }

    @Test func theWhatNowStateCarriesTheDefaultShortcut() throws {
        let h = EngineHarness.tracker(at: wed(10))
        let state = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(state.shortcut == KeyShortcut.trackerDefault)
    }

    @Test func theWhatNowStateCarriesTheShortcutFromThePrefs() throws {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.shortcut = custom }
        let state = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(state.shortcut == custom)
    }

    @Test func theCenterStateCarriesTheShortcutFromThePrefs() throws {
        let h = EngineHarness.tracker(at: wed(10)) { $0.prefs.tracker.shortcut = custom }
        h.start(minutes: 30)
        h.engine.trackerShortcutPressed()
        let state = try #require(h.engine.trackerPromptState(.center))
        #expect(state.shortcut == custom)
    }

    @Test func aShortcutChangedLaterShowsInTheNextState() throws {
        let h = EngineHarness.tracker(at: wed(10))
        h.engine.data.prefs.tracker.shortcut = custom
        let state = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(state.shortcut == custom)
    }

    @Test func thePromptStateListsTheTenNewestRecents() throws {
        let h = EngineHarness.tracker(at: wed(10), activities: work(12))
        let state = try #require(h.engine.trackerPromptState(.whatNow))
        #expect(state.recents.map(\.text) == ["T11", "T10", "T9", "T8", "T7", "T6", "T5", "T4", "T3", "T2"])
    }

    @Test func recentActivitiesNameTheSameTextAndCategoryOnce() {
        let twice = work(3) + [Activity(text: "T0", category: "Coding", start: wed(8), end: wed(8, 10))]
        let h = EngineHarness.tracker(at: wed(10), activities: twice)
        #expect(h.engine.recentActivities.map(\.text) == ["T0", "T2", "T1"])
    }
}
