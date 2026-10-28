import SathiCore
import SwiftUI

struct GeneralTab: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            PageTitle(title: "Hi there", subtitle: "A few things that apply to every buddy.")
            SettingsSection("You") {
                SettingsCard {
                    SettingRow(label: "What should we call you?", showsDivider: false) {
                        TextField("Your name", text: $e.data.prefs.general.name)
                            .textFieldStyle(.plain)
                            .font(Typography.chip)
                            .foregroundStyle(Night.text)
                            .padding(UIMetrics.timeButtonPadding)
                            .frame(width: UIMetrics.fieldWidth)
                            .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
                    }
                }
            }
            SettingsSection("Look and feel") { ThemeCards() }
            SettingsSection("Reminders") {
                SettingsCard {
                    SettingRow(label: "Snooze for", showsDivider: false) {
                        MiniStepper(value: $e.data.prefs.general.snoozeMinutes, range: Limits.snoozeMinutes, step: 1) { "\($0) min" }
                    }
                    SettingRow(label: "Snoozes allowed", hint: "Then only Done or Skip today.") {
                        MiniStepper(
                            value: e.snoozeLimitStep,
                            range: Limits.snoozeLimits.lowerBound ... Engine.noSnoozeLimitStep,
                            step: 1
                        ) { $0 == Engine.noSnoozeLimitStep ? "No limit" : "\($0)" }
                    }
                    SettingRow(label: "Count it as a snooze after") {
                        MiniStepper(value: $e.data.prefs.general.ignoreMinutes, range: Limits.ignoreMinutes, step: 1) { "\($0) min" }
                    }
                }
            }
            SettingsSection("Day summary") {
                SettingsCard {
                    SettingRow(label: "Show my day summary", hint: "A calm look at today's goals.", showsDivider: false) {
                        BuddySwitch(isOn: $e.data.prefs.general.daySummaryOn, accent: Night.sprout, label: "Day summary")
                    }
                    if e.data.prefs.general.daySummaryOn {
                        SettingRow(label: "Show it at") {
                            TimeMenu(minutes: $e.data.prefs.general.daySummaryMinutes, accent: Night.sprout)
                        }
                    }
                }
            }
            SettingsSection("Behaviour") { BehaviourCard() }
        }
    }
}

struct PageTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.textSpacing) {
            Text(verbatim: title)
                .font(Typography.title)
                .foregroundStyle(Night.text)
            Text(verbatim: subtitle)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
        }
    }
}

struct ThemeCards: View {
    var body: some View {
        OptionCardRow {
            OptionCard(title: "Night sprout", detail: "Dark and calm.", isSelected: true, accent: Night.sprout, action: {}, top: {
                ThemeIcon(name: "moon.stars.fill")
            })
            OptionCard(title: "Morning dew", detail: "Soon", isSelected: false, accent: Night.sprout, action: {}, top: {
                ThemeIcon(name: "sun.max.fill")
            })
            .disabled(true)
            OptionCard(title: "Follow macOS", detail: "Soon", isSelected: false, accent: Night.sprout, action: {}, top: {
                ThemeIcon(name: "circle.lefthalf.filled")
            })
            .disabled(true)
        }
    }
}

struct ThemeIcon: View {
    let name: String

    var body: some View {
        Image(systemName: name)
            .foregroundStyle(Night.sprout)
            .accessibilityHidden(true)
    }
}
