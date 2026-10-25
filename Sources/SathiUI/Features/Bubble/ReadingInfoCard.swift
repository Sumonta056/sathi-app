import SathiCore
import SwiftUI

struct ReadingInfoCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book")
                .font(.system(size: 24))
                .foregroundStyle(Night.accent(.reading))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(e.data.prefs.reading.sessionMinutes)-minute session")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("Open your book, then start the timer. Sathi keeps other reminders quiet until you finish.")
                    .font(.system(size: 13))
                    .foregroundStyle(Night.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Night.heroFill(.reading)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Night.heroBorder(.reading), lineWidth: UIMetrics.cardBorder))
    }
}
