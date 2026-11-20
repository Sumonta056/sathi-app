import SwiftUI

struct TodoTickBurst: View {
    let size: CGFloat
    let color: Color
    let idleColor: Color
    @State private var fill = 0.0
    @State private var pop = 0.0
    @State private var ring = 0.0
    @State private var check = 0.0

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(fill > 0 ? color : idleColor, lineWidth: UIMetrics.todoTickBorder)
                .background(Circle().fill(color.opacity(fill)))
            TodoCheckShape()
                .trim(from: 0, to: check)
                .stroke(
                    Night.onAccent,
                    style: StrokeStyle(lineWidth: UIMetrics.todoCheckWidth, lineCap: .round, lineJoin: .round)
                )
            Circle()
                .strokeBorder(color, lineWidth: UIMetrics.todoTickBorder)
                .scaleEffect(1 + UIMetrics.todoRingGrow * ring)
                .opacity(UIMetrics.todoRingOpacity * (1 - ring))
        }
        .modifier(TodoPopEffect(progress: pop))
        .onAppear {
            withAnimation(.easeOut(duration: UIMetrics.todoFillSeconds)) { fill = 1 }
            withAnimation(.linear(duration: UIMetrics.todoPopSeconds)) { pop = 1 }
            withAnimation(.easeOut(duration: UIMetrics.todoRingSeconds)) { ring = 1 }
            withAnimation(.easeOut(duration: UIMetrics.todoCheckSeconds).delay(UIMetrics.todoCheckDelay)) { check = 1 }
        }
    }
}

struct TodoCheckShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * p.x, y: rect.minY + rect.height * p.y)
        }
        var path = Path()
        path.move(to: point(UIMetrics.todoCheckStart))
        path.addLine(to: point(UIMetrics.todoCheckElbow))
        path.addLine(to: point(UIMetrics.todoCheckEnd))
        return path
    }
}

struct TodoPopEffect: ViewModifier, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content.scaleEffect(1 + UIMetrics.todoPopPeak * sin(progress * .pi))
    }
}
