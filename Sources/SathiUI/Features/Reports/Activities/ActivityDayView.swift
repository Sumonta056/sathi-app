import SathiCore
import SwiftUI

struct ActivityDayView: View {
    let day: ActivityDay
    let overview: ActivityDayOverview
    let categories: [ActivityCategory]
    var calendar: Calendar = .current
    var calendars: [CalendarChoice] = []
    var calendarNames: [String: String] = [:]
    var places: [String] = []
    var actions = ActivityDayActions()
    var canUndo = false
    var drawerHosted = false
    @State var editing: ActivityEditTarget?
    @State var selected: Set<ActivityID> = []
    @State var mergeError: String?
    @Environment(\.mainLayout) private var layout

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.activitiesGap) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: UIMetrics.activitiesGap) {
                    topRow
                    ActivityTimelineCard(
                        day: day, count: overview.count, gaps: overview.gapSpans, categories: categories, calendar: calendar,
                        calendars: calendars, calendarNames: calendarNames, actions: actions, canUndo: canUndo,
                        editing: $editing, selected: $selected, mergeError: $mergeError
                    )
                }
                .padding(.bottom, UIMetrics.reportsGap)
            }
            if !layout.drawerEdit, let editing, ActivityEditPanel.shows(editing, in: day) {
                panel(editing).frame(width: UIMetrics.activitiesEditWidth)
            }
        }
        .overlay { if !drawerHosted { drawer } }
        .preference(key: MainDrawerKey.self, value: drawerHosted ? hostedDrawer : nil)
        .onChange(of: day.activities) { selected = ActivityMergeBar.pruned(selected, in: $0) }
        .onChange(of: day.day) { _ in
            editing = nil
            selected = []
            mergeError = nil
            actions.clearMergeUndo()
        }
    }

    @ViewBuilder private var topRow: some View {
        let table = ActivityTableCard(table: ActivityTableCard.day(overview.categories, away: overview.awayTotals, categories: categories))
        if layout.isNarrow {
            VStack(alignment: .leading, spacing: UIMetrics.activitiesGap) {
                ActivityDayTiles(overview: overview, inOneRow: true)
                table
            }
        } else {
            WeightedRow(gap: UIMetrics.activitiesGap, weights: UIMetrics.activitiesTopWeights) {
                table
                ActivityDayTiles(overview: overview)
            }
        }
    }

    @ViewBuilder private var drawer: some View {
        if layout.drawerEdit, let editing, ActivityEditPanel.shows(editing, in: day) {
            MainDrawer(close: { self.editing = nil }, content: { panel(editing) })
        }
    }

    private var hostedDrawer: MainDrawerItem? {
        guard layout.drawerEdit, let editing, ActivityEditPanel.shows(editing, in: day) else { return nil }
        return MainDrawerItem(view: AnyView(drawer))
    }

    private func panel(_ target: ActivityEditTarget) -> some View {
        ActivityEditPanel(
            day: day, target: target, categories: categories, calendar: calendar, calendars: calendars,
            calendarNames: calendarNames, places: places, actions: actions, editing: $editing
        )
    }
}
