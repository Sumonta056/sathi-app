import SwiftUI

private struct TodoFoldHeight: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

struct TodoFold: ViewModifier {
    let leaving: Bool
    let reduceMotion: Bool
    @State private var height: CGFloat?

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { Color.clear.preference(key: TodoFoldHeight.self, value: $0.size.height) })
            .onPreferenceChange(TodoFoldHeight.self) { height = $0 }
            .frame(height: collapsed ? 0 : height, alignment: .top)
            .clipped()
            .opacity(leaving ? 0 : 1)
            .animation(
                .easeIn(duration: reduceMotion ? UIMetrics.todoFadeSeconds : UIMetrics.todoFoldSeconds),
                value: leaving
            )
    }

    private var collapsed: Bool { leaving && !reduceMotion }
}

struct TodoStrike: View {
    let reduceMotion: Bool
    @State private var progress = 0.0

    var body: some View {
        GeometryReader { g in
            Rectangle()
                .frame(width: g.size.width * progress, height: UIMetrics.todoStrikeThickness)
                .offset(y: g.size.height * UIMetrics.todoStrikeLine)
        }
        .foregroundStyle(Night.muted)
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return progress = 1 }
            withAnimation(.easeOut(duration: UIMetrics.todoStrikeSeconds).delay(UIMetrics.todoStrikeDelay)) {
                progress = 1
            }
        }
    }
}
