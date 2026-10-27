import SathiCore
import SathiTestSupport
@testable import SathiUI
import SwiftUI
import Testing
import ViewInspector

@MainActor
@Suite("Streak cell")
struct StreakCellTests {
    private func cells() -> [StreakCell] {
        let off = DayKey(day(2026, 3, 2), calendar: .current)
        let h = EngineHarness {
            $0.prefs.water.daysOff = [off]
            $0.events = [.done(.water, 8, at: day(2026, 3, 1, 12)), .done(.water, 1, at: day(2026, 3, 3, 12))]
        }
        return h.engine.reportScreen(.week, selected: .water).calendar.cells
    }

    private func cell(_ number: Int) throws -> StreakCell {
        try #require(cells().first { $0.day == number })
    }

    private func labels(_ cell: StreakCell) throws -> [String] {
        let sut = try StreakCellView(cell: cell).inspect()
        let own = (try? sut.accessibilityLabel().string()).map { [$0] } ?? []
        let nested = sut.findAll(where: { (try? $0.accessibilityLabel().string()) != nil })
            .compactMap { try? $0.accessibilityLabel().string() }
        return own + nested
    }

    private func fills(_ cell: StreakCell) throws -> [Color] {
        try StreakCellView(cell: cell).inspect()
            .findAll(ViewType.Shape.self)
            .compactMap { try? $0.fillShapeStyle(Color.self) }
    }

    private var shades: [Color] {
        UIMetrics.streakLevelOpacity.map { Night.sprout.opacity($0) }
    }

    @Test func offCellIsLabelledDayOff() throws {
        let off = try cell(2)
        #expect(off.isOff)
        #expect(try labels(off).contains { $0.contains("Day off") })
    }

    @Test func offCellHasNoFill() throws {
        let found = try fills(cell(2))
        #expect(!found.contains(Night.divider))
        #expect(!found.contains { shades.contains($0) })
    }

    @Test func metDayKeepsItsDayNumberLabelAndFullShade() throws {
        let met = try cell(1)
        #expect(!met.isOff)
        #expect(try labels(met).contains("1"))
        #expect(try !labels(met).contains { $0.contains("Day off") })
        #expect(try fills(met).contains(Night.sprout.opacity(UIMetrics.streakLevelOpacity[2])))
    }

    @Test func underHalfDayKeepsItsLightShade() throws {
        let under = try cell(3)
        #expect(!under.isOff)
        #expect(try labels(under).contains("3"))
        #expect(try fills(under).contains(Night.sprout.opacity(UIMetrics.streakLevelOpacity[0])))
    }

    @Test func emptyDayKeepsTheDividerFill() throws {
        let empty = try cell(4)
        #expect(!empty.isOff)
        #expect(try labels(empty).contains("4"))
        #expect(try fills(empty).contains(Night.divider))
    }
}
