import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Today day content")
struct TodayDayContentTests {
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC") ?? .current
        return c
    }()

    private func work(_ d: Int, _ from: Int, _ to: Int, _ category: String) -> Activity {
        Activity(text: "Task", category: category, start: day(2026, 3, d, from), end: day(2026, 3, d, to))
    }

    private func harness() -> EngineHarness {
        let lunch = Activity(kind: .away, text: "", start: day(2026, 3, 4, 13), end: day(2026, 3, 4, 13, 30), awayPlace: .lunch)
        return EngineHarness.tracker(at: day(2026, 3, 4, 14), activities: [
            work(4, 10, 12, "Coding"), work(4, 12, 13, "Meetings"), lunch, work(3, 10, 11, "Coding")
        ])
    }

    private func content(_ h: EngineHarness, _ layout: MainLayout = NarrowSupport.wide) throws -> InspectableView<ViewType.ClassifiedView> {
        try TodayDayContent().environmentObject(h.engine).environment(\.mainLayout, layout).inspect()
    }

    private func texts(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    @Test func showsTheDayCards() throws {
        let sut = try content(harness())
        #expect(throws: Never.self) { try sut.find(TodayNowCard.self) }
        #expect(throws: Never.self) { try sut.find(TodayBuddyGrid.self) }
        #expect(throws: Never.self) { try sut.find(text: "Today so far") }
        #expect(throws: Never.self) { try sut.find(text: "Coming up") }
        #expect(throws: Never.self) { try sut.find(text: "March 2026") }
    }

    @Test func showsTheLoggedChangeVsYesterday() throws {
        #expect(throws: Never.self) { try content(harness()).find(text: "+2h 0m vs yesterday") }
    }

    @Test func showsTheBreakdownLineInsideTodaySoFar() throws {
        let card = try content(harness()).find(TodaySoFarCard.self)
        for text in ["Coding", "2h 0m", "67%", "Meetings", "1h 0m", "33%", "Lunch · Away", "30m", "—"] {
            #expect(throws: Never.self) { try card.find(text: text) }
        }
    }

    @Test func hasNoBreakdownNoHeaderAndNoScroll() throws {
        let h = harness()
        let sut = try content(h)
        _ = try sut.find(TodaySoFarCard.self)
        #expect(Find.lacks(sut, text: "Breakdown"))
        #expect(Find.lacks(sut, text: h.engine.todayScreen.greeting))
        #expect(Find.lacks(sut, text: Copywriter.todayQuickReminder))
        #expect((try? sut.find(ViewType.ScrollView.self)) == nil)
    }

    @Test func trackerOffShowsTheSoFarHintAndNoChange() throws {
        let h = EngineHarness(at: day(2026, 3, 4, 14))
        let sut = try content(h)
        #expect(throws: Never.self) { try sut.find(text: "Today so far") }
        #expect(throws: Never.self) { try sut.find(text: Copywriter.todaySoFarOffHint) }
        #expect(!texts(sut).contains { $0.contains("vs yesterday") })
        #expect(throws: Never.self) { try sut.find(text: "March 2026") }
        #expect(throws: Never.self) { try sut.find(text: "Coming up") }
    }

    private func sofar(change: RangeChange) -> TodaySoFar {
        TodaySoFar(
            isOn: true, hours: DateInterval(start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 18)), segments: [], logged: 3 * 3600,
            categories: [
                ActivityCategoryTotal(name: "Work", isNamed: true, seconds: 2 * 3600, percent: 67),
                ActivityCategoryTotal(name: "Reading", isNamed: true, seconds: 3600, percent: 33)
            ],
            away: [ActivityCategoryTotal(name: "Walk", isNamed: true, seconds: 20 * 60, percent: 0)],
            change: change
        )
    }

    private func card(_ s: TodaySoFar) throws -> InspectableView<ViewType.ClassifiedView> {
        try hosted(TodaySoFarCard(sofar: s, categories: [], calendar: cal, now: day(2026, 3, 4, 12)), EngineHarness()).inspect()
    }

    @Test func breakdownIsLongestFirstWithAwayLastAndADash() throws {
        let all = try texts(card(sofar(change: .up(40 * 60))))
        let work = try #require(all.firstIndex(of: "Work"))
        let reading = try #require(all.firstIndex(of: "Reading"))
        let walk = try #require(all.firstIndex(of: "Walk · Away"))
        #expect(work < reading)
        #expect(reading < walk)
        #expect(all.filter { $0 == "—" }.count == 1)
        #expect(all.contains("20m"))
    }

    @Test func soFarCardShowsTheChangeText() throws {
        #expect(throws: Never.self) { try card(sofar(change: .up(40 * 60))).find(text: "+40m vs yesterday") }
        #expect(throws: Never.self) { try card(sofar(change: .same)).find(text: "same as yesterday") }
    }

    @Test func noChangeHidesTheChangeText() throws {
        #expect(try !texts(card(sofar(change: .none))).contains { $0.contains("yesterday") })
    }

    @Test func trackerOffCardShowsNoBreakdown() throws {
        let all = try texts(card(.off))
        #expect(all.contains(Copywriter.todaySoFarOffHint))
        #expect(!all.contains("—"))
        #expect(!all.contains { $0.contains("yesterday") })
    }

    @Test func breakdownShowsEveryCategory() throws {
        let names = ["A1", "B2", "C3", "D4", "E5", "F6"]
        let acts = names.enumerated().map { i, name in work(4, 8 + i, 9 + i, name) }
        let h = EngineHarness.tracker(at: day(2026, 3, 4, 15), activities: acts) { $0.prefs.tracker.startMinutes = 8 * 60 }
        let all = try texts(content(h).find(TodaySoFarCard.self))
        #expect(names.allSatisfy(all.contains))
    }

    @Test func noRowsMeansNoBreakdownLine() {
        let s = TodaySoFar(
            isOn: true,
            hours: DateInterval(start: day(2026, 3, 4, 9), end: day(2026, 3, 4, 18)),
            segments: [],
            logged: 0,
            categories: []
        )
        #expect((try? card(s).find(TodaySoFarBreakdown.self)) == nil)
    }
}
