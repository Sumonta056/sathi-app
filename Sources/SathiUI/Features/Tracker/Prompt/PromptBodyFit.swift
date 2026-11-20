import SwiftUI

struct PromptBodyFit<Content: View>: View {
    let scrolls: Bool
    @ViewBuilder let content: Content
    @State private var space: CGFloat = 0
    @State private var natural: CGFloat = 0
    @State private var overflows = false

    var body: some View {
        Group {
            if scrolls || overflows {
                ScrollView(.vertical) { measured }
                    .scrollIndicators(.never)
            } else {
                measured
                    .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
                    .clipped()
            }
        }
        .background(GeometryReader { g in Color.clear.preference(key: PromptSpaceKey.self, value: g.size.height) })
        .onPreferenceChange(PromptSpaceKey.self) { space = $0
            refit()
        }
        .onPreferenceChange(PromptNaturalKey.self) { natural = $0
            refit()
        }
    }

    private var measured: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(GeometryReader { g in Color.clear.preference(key: PromptNaturalKey.self, value: g.size.height) })
    }

    private func refit() {
        let now = PromptFit.overflows(content: natural, space: space)
        if now != overflows { overflows = now }
    }
}

struct PromptSpaceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

struct PromptNaturalKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}
