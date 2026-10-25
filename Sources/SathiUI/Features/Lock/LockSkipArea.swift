import SathiCore
import SwiftUI

struct LockSkipArea: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    @State private var confirmSkip = false

    var body: some View {
        if confirmSkip {
            VStack(spacing: UIMetrics.lockSkipSpacing) {
                Text("Skipping resets your \(e.streak(id))-day streak to zero.")
                    .font(.system(size: UIMetrics.fontLockSkipWarning))
                HStack(spacing: UIMetrics.lockSkipButtonSpacing) {
                    Button("Keep my streak") { confirmSkip = false }
                        .buttonStyle(PillButton(kind: .onDark, height: UIMetrics.lockSkipButtonHeight))
                    Button("Skip anyway") { e.emergencySkip(id) }
                        .buttonStyle(PillButton(kind: .danger, height: UIMetrics.lockSkipButtonHeight))
                }
                .frame(width: UIMetrics.lockSkipButtonsWidth)
            }
            .padding(UIMetrics.lockSkipPadding)
            .background(RoundedRectangle(cornerRadius: UIMetrics.lockSkipRadius).fill(Night.text.opacity(UIMetrics.ghostFillOpacity)))
        } else {
            Button {
                confirmSkip = true
            } label: {
                Text("Emergency skip").underline().font(.system(size: UIMetrics.fontLockHint)).foregroundStyle(Night.muted)
            }
            .buttonStyle(.plain)
            .padding(UIMetrics.lockSkipLinkPadding)
        }
    }
}
