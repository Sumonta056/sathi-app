import Foundation
@testable import SathiCore
import Testing

@Suite("CalendarBlockLayout real week")
struct CalendarBlockLayoutRealWeekTests {
    private let minimum: Double = 26
    private static let weekNarrow = Set((0 ... Limits.calendarCascadeMaxDepth).map { CalendarLaneShape(depth: $0, lanes: 2) })

    typealias Day = (rows: [RealWeek.Row], plans: [RealWeek.Plan])

    static let days: [String: Day] = [
        "Sun": (RealWeek.sun, []), "Mon": (RealWeek.mon, RealWeek.monPlans),
        "Tue": (RealWeek.tue, RealWeek.tuePlans), "Wed": (RealWeek.wed, RealWeek.wedPlans)
    ]

    static let views: [Set<CalendarLaneShape>] = [[], weekNarrow]

    private func placed(_ name: String, _ narrow: Set<CalendarLaneShape>) throws -> (input: [CalendarBlock], out: [CalendarPlacedBlock]) {
        let day = try #require(Self.days[name])
        let input = RealWeek.blocks(day.rows, day.plans)
        return (input, CalendarBlockLayout.place(input, within: RealWeek.column, minimumMinutes: minimum, narrow: narrow))
    }

    private func drift(_ placed: [CalendarPlacedBlock]) -> TimeInterval {
        placed.filter { !$0.isBackdrop }
            .flatMap { [$0] + ($0.kidsShown ? $0.children : []) }
            .map { $0.displaySpan.start.timeIntervalSince($0.span.start) }
            .max() ?? 0
    }

    @Test(arguments: ["Sun", "Mon", "Tue", "Wed"], views)
    func noBlockIsCovered(_ name: String, _ narrow: Set<CalendarLaneShape>) throws {
        #expect(try OverlapCheck.problems(placed(name, narrow).out, minimumMinutes: minimum) == [])
    }

    @Test(arguments: ["Sun", "Mon", "Tue", "Wed"])
    func inWeekNoBlockDriftsMoreThanFiveMinutes(_ name: String) throws {
        let shown = try drift(placed(name, Self.weekNarrow).out)
        #expect(shown <= TimeInterval(Limits.calendarGroupRunGapMinutes) * Timing.minute, "\(name) drift \(shown / Timing.minute) min")
    }

    @Test(arguments: ["Sun", "Mon", "Tue", "Wed"])
    func inDayOnlyAHostTitleRowMovesAChildAndNeverMoreThanTheMinimum(_ name: String) throws {
        let shown = try drift(placed(name, []).out)
        #expect(shown <= minimum * Timing.minute, "\(name) drift \(shown / Timing.minute) min")
    }

    @Test(arguments: ["Sun", "Mon", "Tue", "Wed"], views)
    func noBlockIsLost(_ name: String, _ narrow: Set<CalendarLaneShape>) throws {
        let day = try placed(name, narrow)
        #expect(Grp.everyID(day.out) == Set(day.input.map(\.id)))
    }
}
