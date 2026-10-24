import SathiCore
import SwiftUI

struct TimeMenu: View {
    @Binding var minutes: Int

    private var label: String {
        TimeSlots.all.first { $0.minutes == minutes }?.label ?? Fmt.timeOfDay(minutes)
    }

    var body: some View {
        Menu {
            ForEach(TimeSlots.all, id: \.minutes) { slot in
                Button(slot.label) { minutes = slot.minutes }
            }
        } label: {
            Text(verbatim: label)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .padding(UIMetrics.timeButtonPadding)
        .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
        .overlay(
            RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                .strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.chipBorder)
        )
    }
}
