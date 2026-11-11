import AppKit
import SathiCore
import SwiftUI

struct ReportsExportButton: View {
    @EnvironmentObject var e: Engine
    let range: StatsRange
    @State private var failed = false
    @State private var busy = false

    var body: some View {
        HStack(spacing: UIMetrics.tileGap) {
            if failed {
                Text(verbatim: Copywriter.reportsExportFailed)
                    .font(Typography.hint)
                    .foregroundStyle(Night.tracker)
            }
            Button(action: export) {
                Text(verbatim: Copywriter.reportsExport)
                    .font(Typography.chip)
                    .foregroundStyle(Night.text)
                    .padding(UIMetrics.rangeSegmentPadding)
                    .frame(height: UIMetrics.rangeArrowSize)
                    .background(shape.fill(Night.card))
                    .overlay(shape.strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
                    .contentShape(shape)
            }
            .buttonStyle(.plain)
            .disabled(busy)
        }
    }

    private func export() {
        guard let folder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            failed = true
            return
        }
        busy = true
        failed = false
        let engine = e
        let shown = range
        Task { @MainActor in
            let url = engine.exportHistory(shown, to: folder)
            busy = false
            guard let url else {
                failed = true
                return
            }
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
