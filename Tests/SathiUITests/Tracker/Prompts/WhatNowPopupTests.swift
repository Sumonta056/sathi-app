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
        try Prompt.tap(Prompt.recentList(WhatNowPopup(state: s).inspect()), "tracker.recent.chip")
        let draft = try #require(calls.started.first?.0)
        #expect(draft.text == "Review PR")
        #expect(draft.category == "Review")
    }

    @Test func listsEveryRecentInTheDropdown() throws {
        let recents = (0 ..< 10).map { RecentActivity(text: "R\($0)", category: nil, length: 60) }
        let s = Prompt.state(.whatNow) { $0.recents = recents }
        let list = try Prompt.recentList(WhatNowPopup(state: s).inspect())
        #expect(Prompt.texts(list).filter { $0.hasPrefix("R") } == (0 ..< 10).map { "R\($0)" })
        #expect(Prompt.ids(list, prefix: "tracker.recent.chip").count == 10)
    }

    @Test func runningEventIsTheFirstRowOfTheDropdown() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) {
            $0.runningEvent = Prompt.event()
            $0.recents = [RecentActivity(text: "R0", category: nil, length: 60)]
        }
        let list = try Prompt.recentList(WhatNowPopup(state: s).inspect())
        #expect(Prompt.ids(list, prefix: "tracker.").first { $0.hasSuffix(".chip") } == "tracker.event.chip")
        try Prompt.tap(list, "tracker.event.chip")
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

    @Test func categoryAndAskShowAsTheirOwnRows() throws {
        let sut = try WhatNowPopup(state: Prompt.state(.whatNow)).inspect()
        #expect(try sut.find(TrackerCategoryMenu.self).actualView().selected == "Coding")
        #expect(try A11y.isSelected(sut.find(viewWithAccessibilityIdentifier: "tracker.ask.0").find(ViewType.Button.self, relation: .parent)))
        #expect(try !A11y.isSelected(sut.find(viewWithAccessibilityIdentifier: "tracker.ask.5").find(ViewType.Button.self, relation: .parent)))
        #expect(!Prompt.has(sut, "tracker.summary"))
    }

    @Test func skipPassesNoSwitchTimeWithoutTheRow() throws {
        let calls = PromptCalls()
        try Prompt.tap(WhatNowPopup(state: Prompt.state(.whatNow, calls: calls)).inspect(), "tracker.skip")
        #expect(calls.skipped.count == 1)
        #expect(calls.skipped.map { $0 == nil } == [true])
    }
}
