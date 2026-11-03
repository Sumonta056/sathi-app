import SathiCore
import SwiftUI

struct DaysOffRow: View {
    let key: DayKey
    let accent: Color
    let onRemove: () -> Void

    var body: some View {
        let text = Self.label(key)
        HStack {
            Text(verbatim: text)
                .font(Typography.rowLabel)
                .foregroundStyle(Night.text)
            Spacer()
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: UIMetrics.dayOffRemoveIconSize, weight: .heavy))
                    .foregroundStyle(accent)
                    .frame(width: UIMetrics.dayOffRemoveSize, height: UIMetrics.dayOffRemoveSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "Remove \(text)"))
        }
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Night.divider)
                .frame(height: UIMetrics.dividerHeight)
        }
    }

    static func label(_ key: DayKey) -> String {
        formatter.string(from: key.start(in: utc))
    }

    private static let utc = Calendar.gregorian(in: .gmt)

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = utc
        f.timeZone = .gmt
        f.setLocalizedDateFormatFromTemplate("EEEdMMM")
        return f
    }()
}
