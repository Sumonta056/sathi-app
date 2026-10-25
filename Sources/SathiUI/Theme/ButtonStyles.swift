import SwiftUI

struct PillButton: ButtonStyle {
    enum Kind { case primary, ghost, onDark, danger }
    var kind: Kind = .primary
    var height: CGFloat = UIMetrics.pillStyleHeight

    static func colors(_ kind: Kind) -> (fg: Color, bg: Color) {
        let faint = Night.text.opacity(UIMetrics.ghostFillOpacity)
        switch kind {
        case .primary: return (Night.onAccent, Night.sprout)
        case .ghost: return (Night.text, faint)
        case .onDark: return (Night.onAccent, Night.water)
        case .danger: return (Night.cheek, faint)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        let pair = Self.colors(kind)
        return configuration.label
            .font(.system(size: UIMetrics.fontPillStyle, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, UIMetrics.pillStylePadding)
            .frame(maxWidth: .infinity, minHeight: height)
            .foregroundStyle(pair.fg)
            .background(RoundedRectangle(cornerRadius: UIMetrics.pillStyleRadius, style: .continuous).fill(pair.bg))
            .opacity(configuration.isPressed ? UIMetrics.pillPressedOpacity : 1)
            .contentShape(Rectangle())
    }
}
