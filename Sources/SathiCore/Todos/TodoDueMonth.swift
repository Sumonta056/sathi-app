import Foundation

package enum TodoDueMonth {
    package static func month(selected: Date, offset: Int, calendar: Calendar) -> DayOffMonth {
        let g = Calendar.gregorian(in: calendar.timeZone)
        let picked = DayKey(selected, calendar: g)
        let start = g.date(from: g.dateComponents([.year, .month], from: selected)) ?? selected
        let first = g.date(byAdding: .month, value: offset, to: start) ?? start
        return DayOffMonth.build(first: first, calendar: g, canGoBack: true, canGoForward: true) {
            $0 == picked ? .off : .pickable
        }
    }
}
