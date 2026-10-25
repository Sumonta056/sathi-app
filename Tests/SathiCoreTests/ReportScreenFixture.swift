import Foundation
import SathiCore
import SathiTestSupport

struct ReportScreenFixture {
    static let zone = FixedZone.berlin

    var now: Date
    var events: [HistoryEvent] = []
    var prefs = Prefs()
    var enabled: Set<HabitID> = [.water, .reading]
    var streak = 0
    var longest = 0
    var calendar = Self.zone.calendar

    static func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> ReportScreenFixture {
        ReportScreenFixture(now: zone.date(y, m, d, h))
    }

    static func on(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9) -> Date {
        zone.date(y, m, d, h)
    }

    func report(_ range: ReportRange) -> Report {
        ReportBuilder(calendar: calendar).build(range, now: now, events: events, prefs: prefs)
    }

    func screen(_ range: ReportRange, selected: HabitID = .water) -> ReportScreen {
        ReportScreenBuilder(calendar: calendar).build(ReportScreenInput(
            range: range,
            selected: selected,
            report: report(range),
            month: report(.month),
            enabled: enabled,
            streak: streak,
            longest: longest,
            now: now
        ))
    }
}
