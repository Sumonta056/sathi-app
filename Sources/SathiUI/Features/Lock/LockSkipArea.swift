import SathiCore
import SwiftUI

struct LockSkipArea: View {
    @EnvironmentObject var e: Engine
    let id: HabitID

    @State private var confirmSkip = false

    var body: some View {
        if confirmSkip {
            VStack(spacing: 10) {
                Text("Skipping resets your \(e.streak(id))-day streak to zero.")
                    .font(.system(size: 13.5))
                HStack(spacing: 8) {
                    Button("Keep my streak") { confirmSkip = false }
                        .buttonStyle(PillButton(kind: .onDark, height: 38))
                    Button("Skip anyway") { e.emergencySkip(id) }
                        .buttonStyle(PillButton(kind: .danger, height: 38))
                }
                .frame(width: 320)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
        } else {
            Button {
                confirmSkip = true
            } label: {
                Text("Emergency skip").underline().font(.system(size: 13)).foregroundStyle(Palette.lockHint)
            }
            .buttonStyle(.plain)
            .padding(8)
        }
    }
}
