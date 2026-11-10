import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("What now popup")
struct WhatNowPopupTests {
    @Test func startUsesTheDraftDefaults() throws {
        let calls = PromptCalls()
        let sut = try WhatNowPopup(state: Prompt.state(.whatNow, calls: calls)).inspect()
        try Prompt.tap(sut, "tracker.start")
        let draft = try #require(calls.started.first).0
        #expect(draft.text == "Write spec")
        #expect(draft.category == "Coding")
        #expect(draft.length == .minutes(Limits.trackerUsualLengthDefault))
        #expect(draft.askOffsetMinutes == 0)
        #expect(calls.started.map { $0.1 == nil } == [true])
    }

    @Test func startKeepsTheCalendarFromTheDraft() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) { $0.draft.calendarID = "work" }
        try Prompt.tap(WhatNowPopup(state: s).inspect(), "tracker.start")
        #expect(calls.started.first?.0.calendarID == "work")
    }

    @Test func emptyTextDoesNotStart() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) { $0.draft.text = "   " }
        try Prompt.tap(WhatNowPopup(state: s).inspect(), "tracker.start")
        #expect(calls.started.isEmpty)
    }

    @Test func recentChipFillsTextAndCategoryAndStarts() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) {
            $0.recents = [RecentActivity(text: "Review PR", category: "Review", length: 1800)]
        }
        try Prompt.tap(WhatNowPopup(state: s).inspect(), "tracker.recent.chip")
        let draft = try #require(calls.started.first?.0)
        #expect(draft.text == "Review PR")
        #expect(draft.category == "Review")
    }

    @Test func showsOnlyThreeRecents() throws {
        let recents = (0 ..< 5).map { RecentActivity(text: "R\($0)", category: nil, length: 60) }
        let s = Prompt.state(.whatNow) { $0.recents = recents }
        let sut = try WhatNowPopup(state: s).inspect()
        #expect(["R0", "R1", "R2"].allSatisfy { (try? sut.find(text: $0)) != nil })
        #expect((try? sut.find(text: "R3")) == nil)
    }

    @Test func runningEventIsTheFirstChip() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) {
            $0.runningEvent = Prompt.event()
            $0.recents = [RecentActivity(text: "R0", category: nil, length: 60)]
        }
        let sut = try WhatNowPopup(state: s).inspect()
        let chips = sut.findAll(TrackerChip.self)
        #expect(try chips.first?.actualView().label == "Standup")
        try Prompt.tap(sut, "tracker.event.chip")
        #expect(calls.started.first?.0.sourceEventID == "e1")
        #expect(calls.started.first?.0.text == "Standup")
    }

    @Test func alwaysShowsForCalendarAndQuiet() throws {
        let sut = try WhatNowPopup(state: Prompt.state(.whatNow)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "For") }
        #expect(throws: Never.self) { try sut.find(text: "Add to calendar") }
        #expect(throws: Never.self) { try sut.find(text: "No popups until it ends") }
        #expect(Prompt.has(sut, "tracker.for.Open"))
        #expect(Prompt.has(sut, "tracker.calendar.check"))
        #expect(Prompt.has(sut, "tracker.quiet"))
    }

    @Test func summaryLineShowsCategoryAndAsk() throws {
        let sut = try WhatNowPopup(state: Prompt.state(.whatNow)).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Coding · ask when it ends") }
    }

    @Test func skipPassesNoSwitchTimeWithoutTheRow() throws {
        let calls = PromptCalls()
        try Prompt.tap(WhatNowPopup(state: Prompt.state(.whatNow, calls: calls)).inspect(), "tracker.skip")
        #expect(calls.skipped.count == 1)
        #expect(calls.skipped.map { $0 == nil } == [true])
    }
}
