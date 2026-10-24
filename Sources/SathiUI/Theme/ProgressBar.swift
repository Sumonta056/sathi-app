import SwiftUI

struct ProgressBar: View {
    var value: Double
    var tint: Color
    var height: CGFloat = 6
    var track: Color = Color.primary.opacity(0.1)

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint).frame(width: g.size.width * CGFloat(min(1, max(0, value))))
            }
        }
        .frame(height: height)
    }
}
