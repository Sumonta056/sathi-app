import AppKit
import SathiCore
import SwiftUI

struct ReportsExportButton: View {
    @EnvironmentObject var e: Engine
    let range: StatsRange
    @State private var note: String?
    @State private var busy = false

    var body: some View {
        HStack(spacing: UIMetrics.tileGap) {
            if let note {
                Text(verbatim: note)
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
            note = Copywriter.reportsExportFailed
            return
        }
        busy = true
        note = nil
        let engine = e
        let shown = range
        Task { @MainActor in
            let result = engine.exportHistory(shown, to: folder)
            busy = false
            switch result {
            case let .saved(url): NSWorkspace.shared.activateFileViewerSelecting([url])
            case .empty: note = Copywriter.reportsExportEmpty
            case .failed: note = Copywriter.reportsExportFailed
            }
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous)
    }
}
