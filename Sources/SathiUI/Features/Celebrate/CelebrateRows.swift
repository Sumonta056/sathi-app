import SwiftUI

struct CelebrateGlassRow: View {
    let total: Double
    let goal: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< max(1, goal), id: \.self) { i in
                let fill = max(0, min(1, total - Double(i)))
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 5).fill(Palette.ink.opacity(0.08))
                    RoundedRectangle(cornerRadius: 5).fill(Palette.water).frame(height: CGFloat(26 * fill))
                }
                .frame(height: 26)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ReadingWeekRow: View {
    static let labels = ["M", "T", "W", "T", "F", "S", "S"]

    let streak: Int
    let today: Date

    static func mondayIndex(of date: Date, calendar: Calendar = .current) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }

    static func isLit(_ index: Int, weekday: Int, streak: Int) -> Bool {
        index <= weekday && index > weekday - streak
    }

    var body: some View {
        let weekday = Self.mondayIndex(of: today)
        HStack(spacing: 5) {
            ForEach(0 ..< 7, id: \.self) { i in
                let on = Self.isLit(i, weekday: weekday, streak: streak)
                Text(Self.labels[i])
                    .font(.system(size: 11, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .foregroundStyle(on ? Color.white : Palette.muted)
                    .background(Capsule().fill(on ? Palette.book : Palette.ink.opacity(0.08)))
            }
        }
        .padding(.vertical, 6)
    }
}
