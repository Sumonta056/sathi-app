import Foundation
@testable import SathiCore

enum OverlapCheck {
    static func problems(_ placed: [CalendarPlacedBlock], minimumMinutes: Double) -> [String] {
        let least = minimumMinutes * Timing.minute
        let shown = placed.filter { !$0.isBackdrop }
        var found = shown.flatMap { childProblems($0, least: least) }
        for (i, a) in shown.enumerated() {
            for b in shown[(i + 1)...] where meets(a.displaySpan, b.displaySpan) && sharesWidth(a, b) {
                let (top, under) = a.depth >= b.depth ? (a, b) : (b, a)
                if !raisedOver(top, under, least: least) { found.append("\(name(top)) covers \(name(under))") }
            }
        }
        return found
    }

    private static func childProblems(_ host: CalendarPlacedBlock, least: TimeInterval) -> [String] {
        guard host.kidsShown else { return [] }
        let room = DateInterval(start: host.displaySpan.start.addingTimeInterval(least), end: host.displaySpan.end)
        var found = host.children.filter { $0.displaySpan.start < room.start || $0.displaySpan.end > room.end }
            .map { "\(name($0)) sticks out of \(name(host))" }
        for (a, b) in zip(host.children, host.children.dropFirst()) where meets(a.displaySpan, b.displaySpan) {
            found.append("\(name(a)) covers \(name(b))")
        }
        return found
    }

    private static func raisedOver(_ top: CalendarPlacedBlock, _ under: CalendarPlacedBlock, least: TimeInterval) -> Bool {
        let title = DateInterval(start: under.displaySpan.start, duration: least)
        return top.depth > under.depth
            && meets(top.span, under.span)
            && !meets(top.displaySpan, title)
            && !(under.kidsShown && under.children.contains { meets(top.displaySpan, $0.displaySpan) })
    }

    private static func meets(_ a: DateInterval, _ b: DateInterval) -> Bool {
        a.start < b.end && b.start < a.end
    }

    private static func sharesWidth(_ a: CalendarPlacedBlock, _ b: CalendarPlacedBlock) -> Bool {
        a.lane * b.lanes < (b.lane + 1) * a.lanes && b.lane * a.lanes < (a.lane + 1) * b.lanes
    }

    private static func name(_ p: CalendarPlacedBlock) -> String {
        "\(p.block.title) \(clock(p.displaySpan.start))–\(clock(p.displaySpan.end)) d\(p.depth) l\(p.lane)/\(p.lanes)"
    }

    private static func clock(_ date: Date) -> String {
        let minutes = Int(date.timeIntervalSince(Lay.t0) / Timing.minute) + Limits.calendarPageDayStartHour * Limits.minutesPerHour
        return String(format: "%02d:%02d", minutes / Limits.minutesPerHour % Limits.hoursPerDay, minutes % Limits.minutesPerHour)
    }
}
