import SathiCore
import SwiftUI

struct DoNowButton: View {
    let e: Engine
    let habit: HabitID
    var before: () -> Void = {}

    var body: some View {
        if let title = Copywriter.doNowTitle(habit), e.enabled(habit), e.session(habit) == nil {
            Button {
                before()
                e.doNow(habit)
            } label: {
                Text(verbatim: title)
            }
            .buttonStyle(GhostButton(accent: Night.accent(habit), height: UIMetrics.quickSmallButtonHeight))
            .accessibilityIdentifier("doNow.\(habit.rawValue)")
        }
    }
}
