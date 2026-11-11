import SathiCore
import SwiftUI

struct ActivitiesPage: View {
    @EnvironmentObject var e: Engine
    let day: DayKey?
    @State private var picked: StatsRange?
    @State private var memo = RangeMemo<StatsRange, ActivitiesPageData>()

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
        .padding(.top, UIMetrics.titleBarInset)
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
        HStack(spacing: UIMetrics.reportsGap) {
            Text(verbatim: Copywriter.mainPageActivities)
                .font(Typography.tracker(UIMetrics.mainPageTitleFont, .heavy))
                .foregroundStyle(Night.text)
            Spacer(minLength: 0)
            RangeBar(range: Binding(get: { range }, set: { picked = $0 }), now: e.now, calendar: e.rangeCalendar)
            ActivitiesExportButton(range: range)
        }
    }

    @ViewBuilder private func content(_ range: StatsRange) -> some View {
        let page = memo.value(range, range: range, engine: e) { $0.activitiesPage($1) }
        let calendar = e.rangeCalendar
        if !e.data.prefs.tracker.isOn && page.days.isEmpty {
            trackerOff
        } else if let day = page.day {
            ActivityDayView(day: day, categories: e.activityCategories, calendar: calendar, actions: dayActions)
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
        let engine = e
        var a = ActivityDayActions()
        a.edit = { engine.editActivity($0, $1) }
        a.add = { engine.addPastActivity($0) }
        a.delete = { engine.deleteActivity($0) }
        a.saveToCalendar = { engine.saveActivityToCalendar($0) }
        return a
    }

    private var rangeActions: ActivityRangeActions {
        var a = ActivityRangeActions()
        a.openDay = { picked = dayRange($0) }
        return a
    }
}
