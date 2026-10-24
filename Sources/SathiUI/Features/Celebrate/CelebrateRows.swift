import SwiftUI

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
