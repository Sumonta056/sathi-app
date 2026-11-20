import SwiftUI

private struct TodoFoldHeight: PreferenceKey {
    static let defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

struct TodoFold: ViewModifier {
    let phase: TodoFinishPhase?
    let reduceMotion: Bool
    @State private var height: CGFloat?

    static func fixedHeight(phase: TodoFinishPhase?, reduceMotion: Bool, measured: CGFloat?) -> CGFloat? {
        guard let phase else { return nil }
        return phase == .leaving && !reduceMotion ? 0 : measured
    }

    static func clips(phase: TodoFinishPhase?) -> Bool {
        phase == .leaving
    }

    func body(content: Content) -> some View {
        content
            .background { if phase != nil { measure } }
            .frame(height: Self.fixedHeight(phase: phase, reduceMotion: reduceMotion, measured: height), alignment: .top)
            .mask(Rectangle().padding(.all, Self.clips(phase: phase) ? 0 : -UIMetrics.todoRingBleed))
            .opacity(phase == .leaving ? 0 : 1)
            .animation(
                .easeIn(duration: reduceMotion ? UIMetrics.todoFadeSeconds : UIMetrics.todoFoldSeconds),
                value: phase == .leaving
            )
    }

    private var measure: some View {
        GeometryReader { Color.clear.preference(key: TodoFoldHeight.self, value: $0.size.height) }
            .onPreferenceChange(TodoFoldHeight.self) { height = $0 }
    }
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
