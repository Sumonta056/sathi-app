import SathiCore
import SwiftUI

struct HabitSettingsPage<Sections: View>: View {
    @EnvironmentObject var e: Engine
    let habit: HabitID
    let sections: Sections

    init(habit: HabitID, @ViewBuilder sections: () -> Sections) {
        self.habit = habit
        self.sections = sections()
    }

    var body: some View {
        let engine = e
        let on = engine.data.prefs.isEnabled(habit)
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
                sections
            }
            .opacity(on ? 1 : UIMetrics.disabledOpacity)
            .disabled(!on)
            Button("Show a reminder now") { engine.trigger(habit) }
                .buttonStyle(GhostButton(accent: Night.accent(habit)))
                .disabled(!on)
                .opacity(on ? 1 : UIMetrics.disabledOpacity)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            SectionLabel(title)
            content
        }
    }
}
