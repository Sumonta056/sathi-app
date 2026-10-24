import SathiCore
import SwiftUI

struct WaterRhythmCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let engine = e
        let water = engine.data.prefs.water
        SettingsCard {
            SettingRow(label: "Remind me every", showsDivider: false) {
                ChipRow(
                    options: Limits.waterIntervalChips,
                    accent: Night.water,
                    isSelected: { $0 == water.intervalMinutes },
                    onTap: { engine.data.prefs.water.intervalMinutes = $0 },
                    label: { "\($0) min" }
                )
            }
            SettingRow(label: "Between", hint: "Fota sleeps outside these hours.") {
                HStack(spacing: UIMetrics.chipSpacing) {
                    TimeMenu(minutes: $e.data.prefs.water.startMinutes)
                    Text(verbatim: "to")
                        .font(Typography.hint)
                        .foregroundStyle(Night.muted)
                    TimeMenu(minutes: $e.data.prefs.water.endMinutes)
                }
            }
            SettingRow(label: "I drink from") {
                ChipRow(
                    options: Container.allCases,
                    accent: Night.water,
                    isSelected: { $0 == water.container },
                    onTap: { engine.data.prefs.water.container = $0 },
                    label: Self.label
                )
            }
            if water.container == .bottle {
                SettingRow(label: "My bottle holds") {
                    MiniStepper(
                        value: $e.data.prefs.water.bottleSizeGlasses,
                        range: Limits.bottleSizeGlasses,
                        step: Limits.bottleSizeStep,
                        format: Fmt.glasses
                    )
                }
            }
        }
    }

    static func label(_ c: Container) -> String {
        switch c {
        case .glass: return "Glass"
        case .bottle: return "Sip bottle"
        }
    }
}
