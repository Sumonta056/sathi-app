import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Narrow pages")
struct NarrowPageTests {
    private func today(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        try TodayPage().environmentObject(EngineHarness.tracker().engine).environment(\.mainLayout, layout).inspect()
    }

    @Test func narrowTodayScrollsAndUsesOneTableColumn() throws {
        let sut = try today(NarrowSupport.narrow)
        #expect(throws: Never.self) { try sut.find(ViewType.ScrollView.self) }
        #expect(try sut.find(CategoryTableView.self).actualView().columns == UIMetrics.todayBreakdownColumnsNarrow)
    }

    @Test func wideTodayKeepsTwoTableColumnsAndNoScroll() throws {
        let sut = try today(NarrowSupport.wide)
        #expect((try? sut.find(ViewType.ScrollView.self)) == nil)
        #expect(try sut.find(CategoryTableView.self).actualView().columns == UIMetrics.todayBreakdownColumns)
    }

    private func header(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        try TodayHeader(e: EngineHarness().engine, dateLine: "WEDNESDAY", greeting: "Good morning")
            .environment(\.mainLayout, layout)
            .inspect()
    }

    @Test func narrowTodayHeaderPutsTheButtonsUnderTheGreeting() throws {
        let column = try header(NarrowSupport.narrow).vStack()
        #expect(throws: Never.self) { try column.vStack(0).find(text: "Good morning") }
        #expect(throws: Never.self) { try column.hStack(1).find(text: Copywriter.todayQuickReminder) }
    }

    @Test func wideTodayHeaderKeepsTheButtonsBesideTheGreeting() throws {
        let row = try header(NarrowSupport.wide).hStack()
        #expect(throws: Never.self) { try row.find(text: Copywriter.todayQuickReminder) }
    }

    private func score(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        let overview = ReportsFixture.harness().engine.reportsOverview(ReportsFixture.week())
        return try ReportsScoreCard(overview: overview).environment(\.mainLayout, layout).inspect()
    }

    @Test func narrowScoreCardPutsTheSmallRingsOnTheirOwnRow() throws {
        let column = try score(NarrowSupport.narrow).group().vStack(0)
        #expect(throws: Never.self) { try column.hStack(0) }
        #expect(throws: Never.self) { try column.hStack(1) }
    }

    @Test func wideScoreCardKeepsOneRow() throws {
        #expect(throws: Never.self) { try score(NarrowSupport.wide).group().hStack(0) }
    }

    private func buddyTab(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        let tab = ReportsFixture.harness().engine.buddyTab(ReportsFixture.week(), habit: .water)
        return try BuddyTabCard(tab: tab).environment(\.mainLayout, layout).inspect()
    }

    @Test func narrowBuddyTabPutsTheFactsUnderTheChart() throws {
        let column = try buddyTab(NarrowSupport.narrow).group().vStack(0)
        #expect(throws: Never.self) { try column.find(ReportChartView.self) }
        #expect(throws: Never.self) { try column.find(ReportFactsView.self) }
    }

    @Test func wideBuddyTabKeepsTheFactsBesideTheChart() throws {
        #expect(throws: Never.self) { try buddyTab(NarrowSupport.wide).group().hStack(0) }
    }
}
