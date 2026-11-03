import SathiCore
import SwiftUI

struct TimeMenu: View {
    @Binding var minutes: Int
    let accent: Color
    var active = false
    @State private var isOpen = false

    var body: some View {
        Button { isOpen.toggle() } label: {
            Text(verbatim: Fmt.timeOfDay(minutes))
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .fixedSize()
                .padding(UIMetrics.timeButtonPadding)
                .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
                .overlay(
                    RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                        .strokeBorder(Self.border(isOpen: isOpen, active: active, accent: accent), lineWidth: UIMetrics.chipBorder)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            TimePickerGrid(minutes: $minutes, accent: accent)
        }
    }

    static func border(isOpen: Bool, active: Bool, accent: Color) -> Color {
        isOpen || active ? accent : Night.fieldBorder
    }
}
