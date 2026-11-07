import SathiCore
import SwiftUI

struct DayOffCellButton: View {
    let cell: DayOffCell
    let accent: Color
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
        Button(action: action) {
            Text(verbatim: "\(cell.day)")
                .font(Typography.chip)
                .foregroundStyle(foreground)
                .frame(width: UIMetrics.dayChipSize, height: UIMetrics.dayChipSize)
                .background(shape.fill(fill))
                .overlay(shape.strokeBorder(border, lineWidth: UIMetrics.chipBorder))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(cell.state != .pickable)
        .accessibilityLabel(Text(verbatim: DaysOffRow.label(cell.key)))
        .accessibilityValue(Text(verbatim: cell.state == .off ? "Day off" : ""))
    }

    private var foreground: Color {
        switch cell.state {
        case .pickable: return Night.text
        case .off: return accent
        case .unavailable: return Night.faint
        }
    }

    private var fill: Color {
        switch cell.state {
        case .pickable: return Night.bg
        case .off: return accent.opacity(UIMetrics.chipFillOpacity)
        case .unavailable: return .clear
        }
    }

    private var border: Color {
        switch cell.state {
        case .pickable: return Night.fieldBorder
        case .off: return accent
        case .unavailable: return .clear
        }
    }
}
