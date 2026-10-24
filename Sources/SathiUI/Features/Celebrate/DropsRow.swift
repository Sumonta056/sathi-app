import SathiCore
import SwiftUI

enum DropLevel {
    case full, half, empty
}

struct DropsRow: View {
    let total: Double
    let goal: Int

    static func drops(goal: Double) -> Int {
        max(1, Int(goal.rounded(.up)))
    }

    static func level(_ i: Int, total: Double) -> DropLevel {
        let left = total - Double(i)
        if left >= 1 { return .full }
        if left >= 0.5 { return .half }
        return .empty
    }

    var body: some View {
        HStack(spacing: UIMetrics.dropSpacing) {
            ForEach(0 ..< max(1, goal), id: \.self) { i in
                Image(systemName: "drop.fill")
                    .resizable()
                    .frame(width: UIMetrics.dropSize.width, height: UIMetrics.dropSize.height)
                    .foregroundStyle(color(Self.level(i, total: total)))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Fmt.count(total)) of \(goal) glasses")
    }

    private func color(_ l: DropLevel) -> Color {
        switch l {
        case .full: Night.water
        case .half: Night.water.opacity(UIMetrics.halfDropOpacity)
        case .empty: Night.border
        }
    }
}
