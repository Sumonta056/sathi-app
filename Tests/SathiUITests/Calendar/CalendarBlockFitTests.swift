import Foundation
import SathiCore
import SathiTestSupport
@testable import SathiUI
import Testing

@Suite("Calendar block fit")
struct CalendarBlockFitTests {
    private let z = FixedZone.berlin
    private let step: TimeInterval = 7

    private func math(rowMinutes: Int) -> CalendarGridMath {
        CalendarGridMath(
            day: DayKey(z.date(2026, 11, 16), calendar: z.calendar), calendar: z.calendar,
            hourHeight: UIMetrics.calendarHourHeight(rowMinutes: rowMinutes)
        )
    }

    private func starts(_ m: CalendarGridMath, least: TimeInterval) -> [Date] {
        Array(stride(from: m.interval.start, through: m.interval.end.addingTimeInterval(-least), by: step))
    }

    @Test(arguments: Limits.calendarRowMinutes)
    func aBlockAtTheMinimumLengthShowsItsTitleAtAnyStart(_ rowMinutes: Int) {
        let m = math(rowMinutes: rowMinutes)
        let least = m.minimumMinutes * Timing.minute
        let blank = starts(m, least: least).filter {
            !CalendarBlockFit.showsText(height: m.height(DateInterval(start: $0, duration: least)))
        }
        #expect(blank.isEmpty)
    }

    @Test(arguments: Limits.calendarRowMinutes)
    func aHostTitleRowAboveItsFirstChildShowsItsTitleAtAnyStart(_ rowMinutes: Int) {
        let m = math(rowMinutes: rowMinutes)
        let least = m.minimumMinutes * Timing.minute
        let blank = starts(m, least: least).filter {
            !CalendarBlockFit.showsText(height: m.y(for: $0.addingTimeInterval(least)) - m.y(for: $0))
        }
        #expect(blank.isEmpty)
    }

    @Test(arguments: Limits.calendarRowMinutes)
    func aBlockClampedAtTheColumnEndShowsItsTitle(_ rowMinutes: Int) {
        let m = math(rowMinutes: rowMinutes)
        let start = Clamp(m).start
        #expect(start == m.interval.end.addingTimeInterval(-m.minimumMinutes * Timing.minute))
        #expect(CalendarBlockFit.showsText(height: m.height(DateInterval(start: start, end: m.interval.end))))
    }

    @Test func aBlockClearlyBelowTheMinimumStaysBlank() {
        #expect(!CalendarBlockFit.showsText(height: UIMetrics.calendarBlockMinTextHeight - UIMetrics.calendarLine))
    }

    private struct Clamp {
        let start: Date

        init(_ m: CalendarGridMath) {
            let end = m.interval.end
            let early = end.addingTimeInterval(-m.minimumMinutes * Timing.minute * 2)
            let first = Self.block("first", early, early.addingTimeInterval(Timing.minute))
            let next = Self.block("next", early.addingTimeInterval(Timing.minute), early.addingTimeInterval(2 * Timing.minute))
            let placed = CalendarBlockLayout.place([first, next], within: m.interval, minimumMinutes: m.minimumMinutes)
            start = placed.first { $0.block.id == "next" }?.displaySpan.start ?? end
        }

        static func block(_ id: String, _ start: Date, _ end: Date) -> CalendarBlock {
            let a = Activity(text: id, start: start, end: end)
            return CalendarBlock(
                id: id, title: id, interval: a.interval, style: .activity(category: nil),
                source: .activity(a, running: false), isAllDay: false, activityIDs: [a.id]
            )
        }
    }
}
