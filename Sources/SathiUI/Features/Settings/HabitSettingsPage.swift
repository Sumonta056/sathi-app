import SathiCore
import SwiftUI

struct HabitSettingsPage<Sections: View>: View {
    @EnvironmentObject var e: Engine
    let habit: HabitID
    let copy: HeroCopy
    @ViewBuilder let sections: () -> Sections

    var body: some View {
        let engine = e
        let on = engine.data.prefs.isEnabled(habit)
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            HeroCard(
                habit: habit,
                eyebrow: copy.eyebrow,
                title: copy.title,
                hint: copy.hint,
                isOn: engine.enabledBinding(habit),
                switchLabel: copy.switchLabel
            ) {
                StaticBuddy(habit: habit)
            }
            VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
                sections()
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
    @ViewBuilder let content: () -> Content

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            SectionLabel(title)
            content()
        }
    }
}
