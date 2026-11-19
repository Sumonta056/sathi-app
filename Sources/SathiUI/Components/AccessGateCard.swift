import SwiftUI

struct AccessGateCard: View {
    let icon: String
    let accent: Color
    let title: String
    let message: String
    let button: String
    let buttonID: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: UIMetrics.accessGateSpacing) {
            Image(systemName: icon)
                .font(.system(size: UIMetrics.accessGateIcon, weight: .bold))
                .foregroundStyle(accent)
            Text(verbatim: title)
                .font(Typography.cardTitle)
                .foregroundStyle(Night.text)
            Text(verbatim: message)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
                .multilineTextAlignment(.center)
            Button(action: action) { Text(verbatim: button) }
                .buttonStyle(GhostButton(accent: accent))
                .accessibilityIdentifier(buttonID)
        }
        .padding(UIMetrics.accessGatePadding)
        .frame(width: UIMetrics.accessGateWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
