import SathiCore
import SwiftUI

struct TrackerShortcutRow: View {
    @EnvironmentObject var e: Engine
    @StateObject private var recorder = ShortcutRecorder()

    var body: some View {
        let engine = e
        SettingRow(label: Copywriter.trackerShortcutLabel, hint: Copywriter.trackerShortcutHint) {
            HStack(spacing: UIMetrics.chipSpacing) {
                if recorder.isRecording {
                    Text(verbatim: Copywriter.trackerPressKeys).font(Typography.hint).foregroundStyle(Night.tracker)
                } else {
                    keys(engine.trackerShortcut.wrappedValue)
                }
                Button(Copywriter.trackerChange) { toggle() }
                    .buttonStyle(GhostButton(accent: Night.tracker, height: UIMetrics.trackerSmallActionHeight))
                    .accessibilityIdentifier("settings.tracker.shortcut.change")
            }
        }
        .onDisappear { recorder.stop() }
    }

    private func keys(_ s: KeyShortcut) -> some View {
        Text(verbatim: Copywriter.trackerShortcut(s))
            .font(Typography.chip)
            .foregroundStyle(Night.text)
            .padding(UIMetrics.trackerShortcutKeyPadding)
            .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
            .overlay(
                RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous)
                    .strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.chipBorder)
            )
    }

    private func toggle() {
        if recorder.isRecording {
            recorder.stop()
        } else {
            let engine = e
            recorder.start { engine.trackerShortcut.wrappedValue = $0 }
        }
    }
}
