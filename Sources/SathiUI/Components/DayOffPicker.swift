import SathiCore
import SwiftUI

struct DayOffPicker: View {
    let habit: HabitID
    let accent: Color
    @State private var isOpen = false
    @State private var offset = 0

    var body: some View {
        Button { isOpen.toggle() } label: {
            Text(verbatim: "Pick a date")
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .fixedSize()
                .padding(UIMetrics.timeButtonPadding)
                .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
                .overlay(
                    RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                        .strokeBorder(TimeMenu.border(isOpen: isOpen, active: false, accent: accent), lineWidth: UIMetrics.chipBorder)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            DayOffCalendar(habit: habit, accent: accent, offset: $offset)
        }
    }
}
