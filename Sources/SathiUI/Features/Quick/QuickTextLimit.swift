import SwiftUI

struct QuickTextLimit: ViewModifier {
    @Binding var text: String
    let limit: Int

    func body(content: Content) -> some View {
        content.onChange(of: text) { value in
            if value.count > limit { text = String(value.prefix(limit)) }
        }
    }
}
