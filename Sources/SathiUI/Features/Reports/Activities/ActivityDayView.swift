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
    var editing: ActivityEditTarget?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIMetrics.activitiesGap) {
                WeightedRow(gap: UIMetrics.activitiesGap, weights: UIMetrics.activitiesTopWeights) {
                    ActivityTableCard(table: ActivityTableCard.day(overview.categories, categories: categories))
                    ActivityDayTiles(overview: overview)
                }
                ActivityTimelineCard(
                    day: day, count: overview.count, gaps: overview.gapSpans, categories: categories, calendar: calendar, calendars: calendars,
                    calendarNames: calendarNames, actions: actions, editing: editing
                )
                .id(day.day)
                ActivityTextCard(
                    title: Copywriter.activitiesStandupTitle,
                    text: ActivityStandupText.make(day, calendar: calendar), copy: actions.copy
                )
            }
            .padding(.bottom, UIMetrics.reportsGap)
        }
    }
}
