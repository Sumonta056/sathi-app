import Foundation
import SathiCore
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

private let popupKinds: [PromptKind] = [.whatNow, .center]

@MainActor
@Suite("Tracker popup options")
struct TrackerPopupOptionsTests {
    @Test(arguments: popupKinds)
    func everyOptionShowsWithoutATap(_ kind: PromptKind) throws {
        let sut = try Prompt.popup(kind, Prompt.state(kind))
        for text in ["For", "Category", "Ask me", "Add to calendar", "No popups until it ends"] {
            #expect(Prompt.hasText(sut, text), "no text \(text)")
        }
        let ids = [
            "tracker.for.15 min", "tracker.for.30 min", "tracker.for.1 h", "tracker.for.Open",
            "tracker.ask.0", "tracker.ask.5", "tracker.ask.15",
            "tracker.calendar.check", "tracker.quiet", "tracker.recent.menu", "tracker.category.menu"
        ]
        for id in ids {
            #expect(Prompt.has(sut, id), "no \(id)")
        }
    }

    @Test(arguments: popupKinds)
    func theSummaryLineIsGone(_ kind: PromptKind) throws {
        let sut = try Prompt.popup(kind, Prompt.state(kind))
        #expect(!Prompt.has(sut, "tracker.summary"))
        #expect(!Prompt.hasText(sut, "Coding · ask when it ends"))
        #expect(Prompt.has(sut, "tracker.ask.0"))
    }

    @Test(arguments: popupKinds)
    func theCategoryMenuShowsTheDraftCategoryAndAllowsNone(_ kind: PromptKind) throws {
        let menu = try Prompt.popup(kind, Prompt.state(kind)).find(TrackerCategoryMenu.self).actualView()
        #expect(menu.selected == "Coding")
        #expect(menu.idPrefix == "tracker.category.")
        #expect(menu.allowsNone)
        #expect(menu.categories == ActivityCategory.defaults)
    }

    @Test(arguments: popupKinds, [5, 15])
    func anAskMeChipThenStartSendsThatOffset(_ kind: PromptKind, _ offset: Int) throws {
        let calls = PromptCalls()
        let s = Prompt.state(kind, calls: calls)
        let form = TrackerDraftForm(s.draft)
        try Prompt.tap(Prompt.popup(kind, s, form: form), "tracker.ask.\(offset)")
        try Prompt.tap(Prompt.popup(kind, s, form: form), "tracker.start")
        #expect(calls.started.map(\.0.askOffsetMinutes) == [offset])
        #expect(calls.started.first?.0.text == "Write spec")
    }

    @Test(arguments: popupKinds)
    func aCategoryPickThenStartSendsThatCategory(_ kind: PromptKind) throws {
        let calls = PromptCalls()
        let s = Prompt.state(kind, calls: calls)
        let form = TrackerDraftForm(s.draft)
        try Prompt.tap(Prompt.categoryList(Prompt.popup(kind, s, form: form)), "tracker.category.Review")
        try Prompt.tap(Prompt.popup(kind, s, form: form), "tracker.start")
        #expect(calls.started.map(\.0.category) == ["Review"])
    }

    @Test(arguments: popupKinds)
    func theNoCategoryPickThenStartSendsNoCategory(_ kind: PromptKind) throws {
        let calls = PromptCalls()
        let s = Prompt.state(kind, calls: calls)
        let form = TrackerDraftForm(s.draft)
        try Prompt.tap(Prompt.categoryList(Prompt.popup(kind, s, form: form)), "tracker.category.none")
        try Prompt.tap(Prompt.popup(kind, s, form: form), "tracker.start")
        #expect(calls.started.count == 1)
        #expect(calls.started.first?.0.category == nil)
    }

    @Test(arguments: popupKinds)
    func aRecentPickStartsAtOnceWithThatTextAndCategory(_ kind: PromptKind) throws {
        let calls = PromptCalls()
        let s = Prompt.state(kind, calls: calls) { $0.recents = Prompt.recents(10) }
        try Prompt.tap(Prompt.recentList(Prompt.popup(kind, s)), "tracker.recent.chip", row: 3)
        #expect(calls.started.map(\.0.text) == ["Task 3"])
        #expect(calls.started.map(\.0.category) == ["Review"])
        #expect(calls.started.map { $0.1 == nil } == [true])
    }

    @Test(arguments: popupKinds)
    func allTenRecentsAreInTheDropdown(_ kind: PromptKind) throws {
        let s = Prompt.state(kind) { $0.recents = Prompt.recents(10) }
        let list = try Prompt.recentList(Prompt.popup(kind, s))
        #expect(Prompt.texts(list).filter { $0.hasPrefix("Task ") } == (0 ..< 10).map { "Task \($0)" })
    }

    @Test func theCenterPanelShowsTheKeyHintWithTheShortcut() throws {
        let s = Prompt.state(.center) { $0.shortcut = .trackerDefault }
        let sut = try CenterPromptView(state: s).inspect()
        #expect(Prompt.hasText(sut, "↵ start · esc close · ⌃⌥⌘Space from anywhere"))
    }

    @Test func theCenterPanelKeyHintHasNoShortcutPartWithoutAShortcut() throws {
        let sut = try CenterPromptView(state: Prompt.state(.center)).inspect()
        #expect(Prompt.hasText(sut, "↵ start · esc close"))
        #expect(!Prompt.texts(sut).contains { $0.contains("from anywhere") })
    }

    @Test func theCenterPanelSaysUntilWhenTheQuietTimeEnds() throws {
        let s = Prompt.state(.center) { $0.draft.length = .minutes(30) }
        let end = Prompt.now.addingTimeInterval(30 * 60)
        let sut = try CenterPromptView(state: s).inspect()
        #expect(Prompt.hasText(sut, "until " + Copywriter.trackerClock(end, calendar: Prompt.calendar)))
    }

    @Test func theCenterPanelHasNoUntilTextForAnOpenLength() throws {
        let s = Prompt.state(.center) { $0.draft.length = .open }
        let sut = try CenterPromptView(state: s).inspect()
        #expect(Prompt.has(sut, "tracker.quiet"))
        #expect(Prompt.has(sut, "tracker.ask.5"))
        #expect(!Prompt.texts(sut).contains { $0.hasPrefix("until ") })
    }

    @Test func theCenterPanelUsesTheLongAskLabels() throws {
        let sut = try CenterPromptView(state: Prompt.state(.center)).inspect()
        #expect(["When it ends", "5 min after", "15 min after"].allSatisfy { Prompt.hasText(sut, $0) })
        #expect(try !sut.find(TrackerOptionsBox.self).actualView().compact)
        #expect(try !sut.find(TrackerRecentMenu.self).actualView().compact)
    }

    @Test func theCornerPopupUsesTheShortAskLabelsAndNoUntilText() throws {
        let sut = try WhatNowPopup(state: Prompt.state(.whatNow)).inspect()
        #expect(["When it ends", "+5 min", "+15 min"].allSatisfy { Prompt.hasText(sut, $0) })
        #expect(!Prompt.hasText(sut, "5 min after"))
        #expect(!Prompt.texts(sut).contains { $0.hasPrefix("until ") })
        #expect(try sut.find(TrackerOptionsBox.self).actualView().compact)
        #expect(try sut.find(TrackerRecentMenu.self).actualView().compact)
    }

    @Test func theCornerPopupHasNoKeyHintLine() throws {
        let sut = try WhatNowPopup(state: Prompt.state(.whatNow)).inspect()
        #expect(Prompt.has(sut, "tracker.category.menu"))
        #expect(!Prompt.texts(sut).contains { $0.contains("esc") || $0.contains("⇥") })
    }

    @Test func aRecentPickAfterDoneStartsAtThePickedSwitchTime() throws {
        let calls = PromptCalls()
        let s = Prompt.state(.whatNow, calls: calls) {
            $0.recents = Prompt.recents(2)
            $0.switchTimes = [Prompt.now.addingTimeInterval(-300), Prompt.now]
            $0.lastActivity = ActivityDraft(text: "Coding")
        }
        try Prompt.tap(Prompt.recentList(WhatNowPopup(state: s).inspect()), "tracker.recent.chip", row: 1)
        #expect(calls.started.map(\.0.text) == ["Task 1"])
        #expect(calls.started.first?.1 == Prompt.now)
    }
}
