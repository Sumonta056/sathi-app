import SathiCore
import SwiftUI

struct LegacyCelebrate: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        let c = e.celebration
        VStack(spacing: 10) {
            BuddyView(kind: c.id.kind, mood: .cheer, level: 1)
                .frame(width: 110, height: 136)
            Text(badge(c))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Night.onAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(Night.accent(c.id)))
            Text(c.title)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
            Text(subtitle(c))
                .font(.system(size: 14))
                .foregroundStyle(Night.muted)
            switch c.id {
            case .reading: ReadingWeekRow(streak: e.streak(.reading), today: e.now)
            case .water, .meditation: EmptyView()
            }
            Button("Back to work") { e.endCelebrate() }
                .buttonStyle(PillButton(kind: .primary))
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 20)
        .frame(width: 360)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Night.card))
        .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 12)
        .padding(30)
        .foregroundStyle(Night.text)
        .environment(\.colorScheme, .dark)
    }

    private func badge(_ c: Celebration) -> String {
        switch c.id {
        case .water: return "+\(Fmt.glasses(c.amount))"
        case .reading: return "\(Int(c.amount)) min read"
        case .meditation: return "\(Int(c.amount)) min calm"
        }
    }

    private func subtitle(_ c: Celebration) -> String {
        switch c.id {
        case .water:
            return "\(Fmt.count(e.glassesToday)) of \(Int(e.data.prefs.water.dailyGoalGlasses)) glasses today · \(e.streak(.water))-day streak"
        case .reading:
            return "\(e.streak(.reading))-day reading streak"
        case .meditation:
            return "\(e.streak(.meditation))-day calm streak"
        }
    }
}
