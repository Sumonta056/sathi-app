import SwiftUI

struct AddBuddyTab: View {
    struct Idea: Hashable {
        let title: String
        let detail: String
    }

    private static let rows: [[Idea]] = [
        [Idea(title: "Stretch", detail: "Loosen up every hour."), Idea(title: "Eye break", detail: "20 seconds, 20 feet away.")],
        [Idea(title: "Walk", detail: "A short walk after lunch."), Idea(title: "Posture", detail: "Sit tall, shoulders down.")]
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.pageSpacing) {
            PageTitle(title: "Add a buddy", subtitle: "Each buddy is its own module. Turn one on and it gets its own tab.")
            VStack(spacing: UIMetrics.buddyCardSpacing) {
                ForEach(Self.rows, id: \.self) { row in
                    HStack(alignment: .top, spacing: UIMetrics.buddyCardSpacing) {
                        ForEach(row, id: \.self) { BuddyIdeaCard(idea: $0) }
                    }
                }
            }
        }
    }
}

struct BuddyIdeaCard: View {
    let idea: AddBuddyTab.Idea

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
            Text(verbatim: String(idea.title.prefix(1)))
                .font(Typography.rowLabel)
                .foregroundStyle(Night.onAccent)
                .frame(width: UIMetrics.buddyBadgeSize, height: UIMetrics.buddyBadgeSize)
                .background(Circle().fill(Night.sprout))
                .accessibilityHidden(true)
            Text(verbatim: idea.title)
                .font(Typography.rowLabel)
                .foregroundStyle(Night.text)
            Text(verbatim: idea.detail)
                .font(Typography.hint)
                .foregroundStyle(Night.muted)
            Button {} label: {
                Text(verbatim: "Soon")
            }
            .buttonStyle(GhostButton(accent: Night.muted))
            .disabled(true)
        }
        .padding(UIMetrics.optionPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous).fill(Night.card))
        .overlay(RoundedRectangle(cornerRadius: UIMetrics.cardRadius, style: .continuous).strokeBorder(Night.border, lineWidth: UIMetrics.cardBorder))
    }
}
