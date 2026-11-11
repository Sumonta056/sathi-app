import SathiCore
import SwiftUI

struct RangeChangeText: View {
    let change: RangeChange
    let text: String

    var body: some View {
        if !text.isEmpty {
            Text(verbatim: text)
                .font(Typography.hint)
                .foregroundStyle(color)
        }
    }

    private var color: Color {
        switch change {
        case .up: Night.sprout
        case .down: Night.reading
        case .same, .none: Night.muted
        }
    }
}
