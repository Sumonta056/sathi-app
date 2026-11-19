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

    private func dayContent(_ layout: MainLayout) throws -> InspectableView<ViewType.ClassifiedView> {
        try TodayDayContent().environmentObject(EngineHarness.tracker().engine).environment(\.mainLayout, layout).inspect()
    }

    private func texts(_ sut: InspectableView<some BaseViewType>) -> [String] {
        sut.findAll(ViewType.Text.self).compactMap { try? $0.string() }
    }

    @Test func narrowDayStacksTheStreakCalendarFirstThenComingUp() throws {
        let sut = try dayContent(NarrowSupport.narrow)
        let stack = try sut.find(viewWithAccessibilityIdentifier: MainLayout.stackedIdentifier)
        #expect(throws: Never.self) { try stack.find(ViewType.VStack.self) }
        #expect(throws: Never.self) { try stack.find(StreakOverviewView.self) }
        #expect(throws: Never.self) { try stack.find(TodayComingUp.self) }
        let all = texts(stack)
        let month = try #require(all.firstIndex(of: "March 2026"))
        let coming = try #require(all.firstIndex(of: "Coming up"))
        #expect(month < coming)
        #expect((try? sut.find(ViewType.ScrollView.self)) == nil)
    }

    @Test func wideDayPutsTheStreakCalendarBesideComingUp() throws {
        let sut = try dayContent(NarrowSupport.wide)
        #expect((try? sut.find(viewWithAccessibilityIdentifier: MainLayout.stackedIdentifier)) == nil)
        let row = try sut.find(TodayLowerRow.self)
        let both = row.findAll(ViewType.HStack.self).contains {
            (try? $0.find(StreakOverviewView.self)) != nil && (try? $0.find(TodayComingUp.self)) != nil
        }
        #expect(both)
    }
}
