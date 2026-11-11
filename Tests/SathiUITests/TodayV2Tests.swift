import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Today page v2")
struct TodayV2Tests {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .current
        return c
    }()

    private let hours = DateInterval(start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 18))
    private let now = day(2026, 3, 4, 12)

    private func sofar() -> TodaySoFar {
        TodaySoFar(
            isOn: true, hours: hours, segments: [], logged: 3 * 3600,
            categories: [
                ActivityCategoryTotal(name: "Work", isNamed: true, seconds: 2 * 3600, percent: 67),
                ActivityCategoryTotal(name: "Break", isNamed: true, seconds: 3600, percent: 33)
            ]
        )
    }

    @Test func soFarCardShowsTotalSummaryAndRibbon() throws {
        let h = EngineHarness()
        let sut = try hosted(TodaySoFarCard(sofar: sofar(), categories: [], calendar: cal, now: now), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Today so far") }
        #expect(throws: Never.self) { try sut.find(text: "3h 0m") }
        #expect(throws: Never.self) { try sut.find(text: "logged · 100% of tracker hours") }
        #expect(throws: Never.self) { try sut.find(ActivityRibbon.self) }
        #expect(Find.lacks(sut, text: "Breakdown"))
    }

    @Test func soFarCardOffShowsHint() throws {
        let h = EngineHarness()
        let sut = try hosted(TodaySoFarCard(sofar: .off, categories: [], calendar: cal, now: now), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todaySoFarOffHint) }
    }

    @Test func breakdownCardUsesTheTableWithTwoColumns() throws {
        let h = EngineHarness()
        let sut = try hosted(TodayBreakdownCard(sofar: sofar(), categories: []), h).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Breakdown") }
        #expect(throws: Never.self) { try sut.find(text: "Work") }
        let table = try sut.find(CategoryTableView.self).actualView()
        #expect(table.columns == 2)
        #expect(table.showsChange == false)
        #expect(table.summary == "2 categories")
    }

    @Test func comingUpRowShowsTimeAndBadge() throws {
        let item = ComingUpItem(kind: .trackerAsk, title: "Still on it?", time: now.addingTimeInterval(11 * 60))
        let sut = try hosted(TodayComingUp(items: [item], calendar: cal, now: now), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Still on it?") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.trackerClock(item.time, calendar: cal)) }
        #expect(throws: Never.self) { try sut.find(text: "in 11 min") }
    }

    @Test func comingUpRowColors() {
        #expect(TodayComingUp.tint(.trackerAsk) == Night.tracker)
        #expect(TodayComingUp.tint(.daySummary) == Night.spark)
        #expect(TodayComingUp.tint(.quick(UUID())) == Night.quick)
        #expect(TodayComingUp.tint(.habit(.water)) == Night.accent(.water))
    }

    @Test func emptyComingUpSaysNothingMore() throws {
        let sut = try hosted(TodayComingUp(items: [], calendar: cal, now: now), EngineHarness()).inspect()
        #expect(throws: Never.self) { try sut.find(text: "Nothing more today.") }
    }
}
