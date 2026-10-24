import SathiCore
import SwiftUI

struct ReadingInfoCard: View {
    @EnvironmentObject var e: Engine

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "book")
                .font(.system(size: 24))
                .foregroundStyle(Palette.bookDeep)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(e.data.prefs.reading.sessionMinutes)-minute session")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("Open your book, then start the timer. Sathi keeps other reminders quiet until you finish.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.bookCard))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.bookDeep.opacity(0.18), lineWidth: 1))
    }
}
