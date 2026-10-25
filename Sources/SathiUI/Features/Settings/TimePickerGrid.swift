import SathiCore
import SwiftUI

struct TimePickerGrid: View {
    @Binding var minutes: Int
    let accent: Color

    private var parts: TimeParts { TimeParts(minutes: minutes) }
    private static let hourRows = [Array(TimeParts.hours.prefix(6)), Array(TimeParts.hours.suffix(6))]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.timePickerSpacing) {
            SectionLabel("Hour")
            ForEach(Self.hourRows, id: \.self) { row in
                ChipRow(
                    options: row,
                    accent: accent,
                    isSelected: { $0 == parts.hour },
                    onTap: { minutes = parts.with(hour: $0).minutes },
                    label: { "\($0)" },
                    chipWidth: UIMetrics.hourChipWidth
                )
            }
            SectionLabel("Minute")
            ChipRow(
                options: TimeParts.minuteOptions,
                accent: accent,
                isSelected: { $0 == parts.minute },
                onTap: { minutes = parts.with(minute: $0).minutes },
                label: { String(format: ":%02d", $0) },
                chipWidth: UIMetrics.minuteChipWidth
            )
            ChipRow(
                options: [false, true],
                accent: accent,
                isSelected: { $0 == parts.isPM },
                onTap: { minutes = parts.with(isPM: $0).minutes },
                label: { $0 ? "PM" : "AM" },
                chipWidth: UIMetrics.minuteChipWidth
            )
        }
        .padding(UIMetrics.timePickerPadding)
        .background(Night.card)
        .environment(\.colorScheme, .dark)
    }
}
