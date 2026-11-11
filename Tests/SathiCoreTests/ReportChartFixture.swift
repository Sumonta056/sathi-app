import Foundation
import SathiCore
import SathiTestSupport

struct ReportChartFixture {
    static let zone = FixedZone.berlin

    var now: Date
    var events: [HistoryEvent] = []
    var prefs = Prefs()
    var calendar = Self.zone.calendar

    static func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> ReportChartFixture {
        ReportChartFixture(now: zone.date(y, m, d, h))
    }

    static func on(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9) -> Date {
        zone.date(y, m, d, h)
    }

    func report(_ range: ReportRange) -> Report {
        ReportBuilder(calendar: calendar).build(range, now: now, events: events, prefs: prefs)
    }

    func chart(_ range: ReportRange, selected: HabitID = .water) -> ReportChart {
        ReportChartBuilder(calendar: calendar).chart(range, habit: ReportChartBuilder.habitReport(selected, in: report(range)))
    }
}
