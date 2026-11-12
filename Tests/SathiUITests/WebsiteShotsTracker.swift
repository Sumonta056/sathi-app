import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing

@MainActor
@Suite("Website shots, activity tracker", .enabled(if: ShotFolder.path != nil))
struct WebsiteShotsTracker {
    private static func at(_ h: Int, _ m: Int = 0) -> Date { day(2026, 3, 26, h, m) }

    private static func item(_ text: String, _ category: String?, _ from: (Int, Int), _ to: (Int, Int)) -> Activity {
        Activity(text: text, category: category, start: at(from.0, from.1), end: at(to.0, to.1))
    }

    private static var sampleDay: [Activity] {
        [
            item("Inbox and chat", "Email", (9, 0), (9, 30)),
            Activity(kind: .event, text: "Standup", category: "Meeting", start: at(9, 30), end: at(9, 45), sourceEventID: "standup"),
            item("Write spec", "Coding", (9, 45), (11, 30)),
            item("Code review", "Review", (11, 30), (12, 30)),
            Activity(
                kind: .away, text: Copywriter.trackerAwayText(.lunch), start: at(12, 30), end: at(13, 15), awayPlace: .lunch
            ),
            item("Fix login bug", "Coding", (13, 15), (15, 0)),
            Activity(kind: .event, text: "Design sync", category: "Meeting", start: at(15, 0), end: at(15, 45), sourceEventID: "sync"),
            Activity(kind: .buddy, text: "Breathing", category: "Meditation", start: at(15, 45), end: at(15, 55)),
            item("Read the API docs", "Learning", (15, 55), (16, 40)),
            item("Code review", "Review", (16, 40), (17, 30))
        ]
    }

    private static var categories: [ActivityCategory] {
        ActivityCategory.defaults.filter { $0.name != "Cefalo Meetings" } + [ActivityCategory.buddy(.meditation)]
    }

    private static func harness(at start: Date) -> EngineHarness {
        EngineHarness.tracker(at: start, activities: sampleDay) {
            $0.prefs.general.name = "Alex"
            $0.prefs.tracker.categories = categories
            $0.events = Shots.sampleEvents()
        }
    }

    private static func prompt(_ kind: PromptKind, at now: Date) -> TrackerPromptState {
        var s = TrackerPromptState(kind: kind, shownAt: now, now: now, draft: ActivityDraft(text: "", category: "Coding"))
        s.categories = categories
        s.calendars = [CalendarChoice(id: "work", title: "Work", account: "iCloud", colorHex: 0x4CC3F5)]
        s.recents = [
            RecentActivity(text: "Code review", category: "Review", length: 1800),
            RecentActivity(text: "Standup", category: "Meeting", length: 900),
            RecentActivity(text: "Write spec", category: "Coding", length: 3600)
        ]
        return s
    }

    @Test func whatNow() throws {
        let h = Self.harness(at: Self.at(10, 30))
        try Shots.save(WhatNowPopup(state: Self.prompt(.whatNow, at: Self.at(10, 30))), "tracker-what-now", h)
    }

    @Test func stillOn() throws {
        let h = Self.harness(at: Self.at(14, 0))
        var s = Self.prompt(.stillOnIt, at: Self.at(14, 0))
        var running = RunningActivity(
            text: "Fix login bug", category: "Coding", start: Self.at(13, 15), expectedLength: .minutes(45), askAt: Self.at(14, 0)
        )
        running.lastAnswer = Self.at(13, 15)
        s.running = running
        try Shots.save(StillOnItPopup(state: s), "tracker-still-on", h)
    }

    @Test func report() throws {
        let h = Self.harness(at: Self.at(17, 40))
        let view = ReportsView(tab: .activities)
        try Shots.save(view, "tracker-report", h)
    }

    @Test func endOfDay() throws {
        let h = Self.harness(at: Self.at(18, 0))
        let s = TrackerEndOfDayState(day: h.engine.activityDay(DayKey(Self.at(12), calendar: .current)), categories: h.engine.activityCategories)
        try Shots.save(EndOfDayView(state: s), "tracker-end-of-day", h, settle: 1.5)
    }
}
