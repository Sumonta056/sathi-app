import SathiCore
import SwiftUI

struct OpenSathiButton: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        Button {
            MenuBarWindow.close()
            e.openMain(.dashboard(.day))
        } label: {
            Text(verbatim: Copywriter.quickPanelOpen)
                .font(Typography.cardTitle)
                .foregroundStyle(Night.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: UIMetrics.quickOpenHeight)
                .background(shape.fill(Night.water))
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quick.openSathi")
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.quickOpenRadius, style: .continuous)
    }
}
