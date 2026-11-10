import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Tracker recent menu")
struct TrackerRecentMenuTests {
    private func menu(_ s: TrackerPromptState, picks: Box<[ActivityDraft]> = Box([])) -> TrackerRecentMenu {
        TrackerRecentMenu(state: s, draft: s.draft) { picks.value.append($0) }
    }

    private func full(_ configure: (inout TrackerPromptState) -> Void = { _ in }) -> TrackerPromptState {
        Prompt.state(.whatNow) {
            $0.recents = Prompt.recents(10)
            configure(&$0)
        }
    }

    @Test func theButtonShowsRecentAndTheHint() throws {
        let sut = try menu(full()).inspect()
        #expect(Prompt.has(sut, "tracker.recent.menu"))
        #expect(Prompt.hasText(sut, "Recent"))
        #expect(Prompt.hasText(sut, "Pick from your last 10"))
    }

    @Test func theListHasTheHeader() throws {
        let list = try menu(full()).list.inspect()
        #expect(Prompt.hasText(list, "Last 10 · newest first"))
    }

    @Test func tenRecentsGiveTenRowsInTheOrderOfTheState() throws {
        let list = try menu(full()).list.inspect()
        #expect(Prompt.ids(list, prefix: "tracker.recent.chip").count == 10)
        #expect(Prompt.texts(list).filter { $0.hasPrefix("Task ") } == (0 ..< 10).map { "Task \($0)" })
    }

    @Test func aRowShowsTheCategoryName() throws {
        let s = Prompt.state(.whatNow) { $0.recents = [RecentActivity(text: "Review PR", category: "Review", length: 1800)] }
        let list = try menu(s).list.inspect()
        #expect(Prompt.hasText(list, "Review PR"))
        #expect(Prompt.hasText(list, "Review"))
    }

    @Test func aPickCallsOnPickWithThatTextAndCategory() throws {
        let picks = Box<[ActivityDraft]>([])
        let list = try menu(full(), picks: picks).list.inspect()
        try Prompt.tap(list, "tracker.recent.chip", row: 3)
        try Prompt.tap(list, "tracker.recent.chip", row: 9)
        #expect(picks.value.map(\.text) == ["Task 3", "Task 9"])
        #expect(picks.value.map(\.category) == ["Review", "Coding"])
    }

    @Test func aPickKeepsTheOtherDraftFields() throws {
        let picks = Box<[ActivityDraft]>([])
        let s = full {
            $0.draft.length = .minutes(60)
            $0.draft.askOffsetMinutes = 15
        }
        try Prompt.tap(menu(s, picks: picks).list.inspect(), "tracker.recent.chip", row: 0)
        #expect(picks.value.first?.length == .minutes(60))
        #expect(picks.value.first?.askOffsetMinutes == 15)
        #expect(picks.value.first?.sourceEventID == nil)
    }

    @Test func theRunningEventIsTheFirstRow() throws {
        let picks = Box<[ActivityDraft]>([])
        let s = full { $0.runningEvent = Prompt.event() }
        let list = try menu(s, picks: picks).list.inspect()
        let rows = Prompt.ids(list, prefix: "tracker.").filter { $0 == "tracker.event.chip" || $0 == "tracker.recent.chip" }
        #expect(rows.first == "tracker.event.chip")
        #expect(rows.count == 11)
        #expect(Prompt.hasText(list, "Standup"))
        try Prompt.tap(list, "tracker.event.chip")
        #expect(picks.value.first?.text == "Standup")
        #expect(picks.value.first?.sourceEventID == "e1")
    }

    @Test func noEventRowWithoutARunningEvent() throws {
        let list = try menu(full()).list.inspect()
        #expect(Prompt.ids(list, prefix: "tracker.recent.chip").count == 10)
        #expect(!Prompt.has(list, "tracker.event.chip"))
    }

    @Test func theButtonCannotBeTappedWithNothingToPick() throws {
        let filled = try menu(full()).inspect()
        #expect(throws: Never.self) { try Prompt.tap(filled, "tracker.recent.menu") }
        let event = try menu(Prompt.state(.whatNow) { $0.runningEvent = Prompt.event() }).inspect()
        #expect(throws: Never.self) { try Prompt.tap(event, "tracker.recent.menu") }
        let empty = try menu(Prompt.state(.whatNow)).inspect()
        #expect(Prompt.has(empty, "tracker.recent.menu"))
        #expect(throws: (any Error).self) { try Prompt.tap(empty, "tracker.recent.menu") }
    }
}
