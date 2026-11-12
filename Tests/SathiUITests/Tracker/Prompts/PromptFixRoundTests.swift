import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Prompt fix round")
struct PromptFixRoundTests {
    @Test func enterWithTextStartsWithDefaults() throws {
        let calls = PromptCalls()
        let view = WhatNowPopup(state: Prompt.state(.whatNow, calls: calls))
        try view.inspect().find(LazyTextField.self).actualView().onSubmit()
        #expect(calls.started.first?.0.text == "Write spec")
        #expect(calls.started.first?.0.category == "Coding")
        #expect(calls.continued.isEmpty)
    }

    @Test func enterWithEmptyTextContinuesWhenResumeExists() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) {
            $0.draft.text = ""
            $0.resume = ActivityDraft(text: "Coding")
            $0.switchTimes = [Prompt.now]
        }
        try WhatNowPopup(state: s).inspect().find(LazyTextField.self).actualView().onSubmit()
        #expect(calls.continued.map { $0 == Prompt.now } == [true])
        #expect(calls.started.isEmpty)
    }

    @Test func enterWithEmptyTextAndNoResumeDoesNothing() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) { $0.draft.text = "" }
        try WhatNowPopup(state: s).inspect().find(LazyTextField.self).actualView().onSubmit()
        #expect(calls.started.isEmpty)
        #expect(calls.continued.isEmpty)
    }

    @Test func enterWithTextAndResumeStartsTheText() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) { $0.resume = ActivityDraft(text: "Coding") }
        try WhatNowPopup(state: s).inspect().find(LazyTextField.self).actualView().onSubmit()
        #expect(calls.started.count == 1)
        #expect(calls.continued.isEmpty)
    }

    @Test func recentChipKeepsAForPickMadeBefore() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) {
            $0.recents = [RecentActivity(text: "Review PR", category: "Review", length: 1800)]
        }
        let form = TrackerDraftForm(s.draft)
        let forTap = "tracker.for.1 h"
        try Prompt.tap(WhatNowPopup(state: s, form: form).inspect(), forTap)
        try Prompt.tap(Prompt.recentList(WhatNowPopup(state: s, form: form).inspect()), "tracker.recent.chip")
        #expect(calls.started.first?.0.length == .minutes(60))
        #expect(calls.started.first?.0.text == "Review PR")
    }

    @Test func manyCategoriesEachGetARowInTheDropdown() throws {
        let many = (0 ..< 12).map { ActivityCategory(name: "C\($0)", colorHex: 0x4CC3F5) }
        var s = TrackerNoteState(note: .event(Prompt.event()), calendarTitle: "Work", category: nil)
        s.categories = many
        s.calendar = Prompt.calendar
        let rows = try Prompt.ids(Prompt.categoryList(TrackerNoteView(state: s).inspect()), prefix: "tracker.note.category.")
        #expect(rows.count == 12)
        let ask = Prompt.state(.eventAsk) { $0.event = Prompt.event(); $0.categories = many }
        let askRows = try Prompt.ids(Prompt.categoryList(EventAskPopup(state: ask).inspect()), prefix: "tracker.eventCategory.")
        #expect(askRows.count == 12)
    }
}
