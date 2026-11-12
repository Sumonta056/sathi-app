import SathiCore
import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var e: Engine
    @State private var range: ReportRange
    @State private var selected: HabitID
    @State private var tab: ReportsTab
    @State private var activityRange = ActivityRange.day
    @State private var activityDay: DayKey?

    init(range: ReportRange = .week, selected: HabitID = .water, tab: ReportsTab = .habits) {
        _range = State(initialValue: range)
        _selected = State(initialValue: selected)
        _tab = State(initialValue: tab)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.reportsGap) {
            HStack {
                PillSegment(options: ReportsTab.allCases, selected: $tab, title: \.title)
                Spacer(minLength: 0)
                if tab == .activities {
                    PillSegment(options: ActivityRange.allCases, selected: $activityRange, title: \.title)
                }
            }
            switch tab {
            case .habits: HabitReportsView(range: $range, selected: $selected)
            case .activities: ActivityReportsView(range: $activityRange, day: $activityDay)
            }
        }
        .padding(UIMetrics.reportsPadding)
        .padding(.top, UIMetrics.titleBarInset)
        .frame(width: UIMetrics.reportsSize.width, height: UIMetrics.reportsSize.height, alignment: .topLeading)
        .background(Night.bg)
        .ignoresSafeArea()
        .onAppear(perform: openAskedDay)
        .onChange(of: e.activityReportDay) { _ in openAskedDay() }
    }

    private func openAskedDay() {
        guard let asked = e.takeActivityReportDay() else { return }
        tab = .activities
        activityRange = .day
        activityDay = asked
    }
}
