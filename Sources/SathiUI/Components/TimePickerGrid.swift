import SathiCore
import SwiftUI

struct TimePickerGrid: View {
    @Binding var minutes: Int
    let accent: Color

    private var parts: TimeParts { TimeParts(minutes: minutes) }
    private static let hourRows = halves(TimeParts.hours)
    static let minuteRows = halves(TimeParts.minuteOptions)

    private static func halves(_ items: [Int]) -> [[Int]] {
        let half = (items.count + 1) / 2
        return [Array(items.prefix(half)), Array(items.dropFirst(half))]
    }

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
            ForEach(Self.minuteRows, id: \.self) { row in
                ChipRow(
                    options: row,
                    accent: accent,
                    isSelected: { $0 == parts.minute },
                    onTap: { minutes = parts.with(minute: $0).minutes },
                    label: { String(format: ":%02d", $0) },
                    chipWidth: UIMetrics.hourChipWidth
                )
            }
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
