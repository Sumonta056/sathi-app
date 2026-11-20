import SathiCore
import SwiftUI

struct ActivitiesPage: View {
    @EnvironmentObject var e: Engine
    let day: DayKey?
    @State private var picked: StatsRange?
    @State private var memo = RangeMemo<StatsRange, ActivitiesPageData>()
    @State private var overviewMemo = RangeMemo<StatsRange, ActivityDayOverview>()

    init(day: DayKey? = nil, range: StatsRange? = nil) {
        self.day = day
        _picked = State(initialValue: range)
    }

    var body: some View {
        let range = shown
        VStack(alignment: .leading, spacing: UIMetrics.reportsPageGap) {
            header(range)
            content(range)
        }
        .padding(UIMetrics.mainContentPadding)
        .mainDrawerHost()
        .onChange(of: day) { _ in picked = nil }
    }

    private var shown: StatsRange {
        if let picked { return picked }
        guard let day else { return e.currentRange(.day) }
        return dayRange(day)
    }

    private func dayRange(_ key: DayKey) -> StatsRange {
        .containing(key.start(in: e.rangeCalendar), kind: .day, calendar: e.rangeCalendar)
    }

    private func header(_ range: StatsRange) -> some View {
        PageHeader(title: Copywriter.mainPageActivities) {
            RangeBar(range: Binding(get: { range }, set: { picked = $0 }), now: e.now, calendar: e.rangeCalendar)
            textButton(range)
            ActivitiesExportButton(range: range)
        }
    }

    @ViewBuilder private func textButton(_ range: StatsRange) -> some View {
        let isDay = range.kind == .day
        ActivitiesTextButton(
            label: isDay ? Copywriter.activitiesStandupButton : Copywriter.activitiesSummaryButton,
            title: isDay ? Copywriter.activitiesStandupTitle : Copywriter.activitiesRangeTextTitle,
            copyLabel: isDay ? Copywriter.activitiesCopyStandup : Copywriter.activitiesCopy
        ) { sheetText(range) }
    }

    private func sheetText(_ range: StatsRange) -> String {
        let page = memo.value(range, range: range, engine: e) { $0.activitiesPage($1) }
        let calendar = e.rangeCalendar
        if let day = page.day { return ActivityStandupText.make(day, calendar: calendar) }
        let title = Copywriter.rangeTitle(range, now: e.now, calendar: calendar)
        return ActivityRangeText.make(page.days, title: title, calendar: calendar)
    }

    @ViewBuilder private func content(_ range: StatsRange) -> some View {
        let page = memo.value(range, range: range, engine: e) { $0.activitiesPage($1) }
        let calendar = e.rangeCalendar
        if !e.data.prefs.tracker.isOn && page.days.isEmpty {
            trackerOff
        } else if let day = page.day {
            ActivityDayView(
                day: day, overview: overviewMemo.value(range, range: range, engine: e) { $0.activityDayOverview($1) },
                categories: e.activityCategories, calendar: calendar, calendars: e.calendarChoices(),
                calendarNames: e.activityCalendarTitles, places: e.awayPlaces, actions: dayActions, canUndo: e.mergeUndo != nil, drawerHosted: true
            )
        } else if let stats = page.stats {
            ActivityRangeView(
                range: range, days: page.days, stats: stats, categories: e.activityCategories,
                calendar: calendar, now: e.now, actions: rangeActions
            )
        }
    }

    private var trackerOff: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            Text(verbatim: Copywriter.activitiesTrackerOff)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            Button(Copywriter.activitiesTurnOn) { e.openSettings(.tracker) }
                .buttonStyle(GhostButton(accent: Night.tracker))
        }
    }

    private var dayActions: ActivityDayActions {
        ActivityDayActions.merging(e)
    }

    private var rangeActions: ActivityRangeActions {
        var a = ActivityRangeActions()
        a.openDay = { picked = dayRange($0) }
        return a
    }
}
