import SwiftUI

struct GoalMetBadge: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: UIMetrics.goalBadgeIcon, weight: .heavy))
            .foregroundStyle(Night.onAccent)
            .frame(width: UIMetrics.goalBadgeSize, height: UIMetrics.goalBadgeSize)
            .background(Circle().fill(Night.sprout))
            .overlay(Circle().stroke(Night.card, lineWidth: UIMetrics.goalBadgeRim))
            .accessibilityLabel("Goal met")
    }
}
