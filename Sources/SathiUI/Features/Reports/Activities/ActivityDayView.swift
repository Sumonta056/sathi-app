import SathiCore
import SwiftUI

struct ActivityDayView: View {
    let day: ActivityDay
    let overview: ActivityDayOverview
    let categories: [ActivityCategory]
    var calendar: Calendar = .current
    var calendars: [CalendarChoice] = []
    var calendarNames: [String: String] = [:]
    var actions = ActivityDayActions()
    @State var editing: ActivityEditTarget?

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.activitiesGap) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: UIMetrics.activitiesGap) {
                    WeightedRow(gap: UIMetrics.activitiesGap, weights: UIMetrics.activitiesTopWeights) {
                        ActivityTableCard(table: ActivityTableCard.day(overview.categories, away: overview.awayTotals, categories: categories))
                        ActivityDayTiles(overview: overview)
                    }
                    ActivityTimelineCard(
                        day: day, count: overview.count, gaps: overview.gapSpans, categories: categories, calendar: calendar,
                        calendars: calendars, calendarNames: calendarNames, actions: actions, editing: $editing
                    )
                }
                .padding(.bottom, UIMetrics.reportsGap)
            }
            if let editing, ActivityEditPanel.shows(editing, in: day) {
                ActivityEditPanel(
                    day: day, target: editing, categories: categories, calendar: calendar, calendars: calendars,
                    calendarNames: calendarNames, actions: actions, editing: $editing
                )
                .frame(width: UIMetrics.activitiesEditWidth)
            }
        }
        .onChange(of: day.day) { _ in editing = nil }
    }
}
