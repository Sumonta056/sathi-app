import SathiCore
import SwiftUI

struct PromptRecentItem {
    enum Source {
        case recent(RecentActivity)
        case event(CalendarEventInfo)
    }

    let text: String
    let detail: String
    let color: Color
    let source: Source

    init(recent: RecentActivity, categories: [ActivityCategory]) {
        text = recent.text
        detail = Copywriter.activityPromptRecentDetail(category: recent.category, length: recent.length)
        color = categories.first { $0.name == recent.category }.map { Night.category($0.colorHex) } ?? Night.promptDim
        source = .recent(recent)
    }

    init(event: CalendarEventInfo, calendar: Calendar) {
        text = event.title
        detail = Copywriter.trackerSpan(event.start, event.end, calendar: calendar)
        color = Night.trackerEvent
        source = .event(event)
    }
}

struct PromptRecentCard: View {
    let item: PromptRecentItem
    let index: Int
    let filled: Bool
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptCardRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: UIMetrics.promptCardGap) {
                RoundedRectangle(cornerRadius: UIMetrics.promptCardBar / 2)
                    .fill(item.color)
                    .frame(width: UIMetrics.promptCardBar)
                VStack(alignment: .leading, spacing: UIMetrics.promptCardLines) {
                    Text(verbatim: item.text)
                        .font(Typography.tracker(UIMetrics.promptCardNameFont, .bold))
                        .foregroundStyle(Night.text)
                    Text(verbatim: item.detail)
                        .font(Typography.tracker(UIMetrics.promptCardDetailFont, .medium))
                        .foregroundStyle(Night.promptSecondary)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                if let key { keyLabel(key) }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(UIMetrics.promptCardPadding)
            .background(shape.fill(filled ? Night.promptCardFilled : Night.promptCard))
            .overlay(shape.strokeBorder(filled ? Night.tracker : Night.promptCardLine, lineWidth: UIMetrics.promptBorder))
            .contentShape(shape)
            .accessibilityIdentifier("prompt.recent.\(index)")
        }
        .buttonStyle(TrackerPressStyle())
        .modifier(PromptKey.recent(index))
        .accessibilityAddTraits(filled ? .isSelected : [])
    }

    private var key: String? {
        index < UIMetrics.recentKeys ? Copywriter.activityPromptKey(index + 1) : nil
    }

    private func keyLabel(_ key: String) -> some View {
        Text(verbatim: key)
            .font(.system(size: UIMetrics.promptKeyFont, weight: .medium, design: .monospaced))
            .foregroundStyle(Night.faint)
            .padding(UIMetrics.promptKeyPadding)
            .overlay(
                RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous)
                    .strokeBorder(Night.promptBoxLine, lineWidth: UIMetrics.promptBorder)
            )
    }
}
