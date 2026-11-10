import SathiCore
import SwiftUI

struct RibbonReveal {
    var revealed: Bool
    var grow: Double
    var stagger: Double
}

struct ActivityRibbon: View {
    let segments: [ActivitySegment]
    let hours: DateInterval
    let categories: [ActivityCategory]
    var height: CGFloat = UIMetrics.trackerRibbonHeight
    var radius: CGFloat = UIMetrics.trackerRibbonRadius
    var showsLabels = true
    var reveal: RibbonReveal?

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Night.trackerWell)
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    block(segment, index: index, width: g.size.width)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
        .frame(height: height)
    }

    static func fraction(_ segment: ActivitySegment, in hours: DateInterval) -> (start: Double, width: Double) {
        guard hours.duration > 0 else { return (0, 0) }
        let start = segment.interval.start.timeIntervalSince(hours.start) / hours.duration
        return (start, segment.interval.duration / hours.duration)
    }

    private func block(_ segment: ActivitySegment, index: Int, width: CGFloat) -> some View {
        let f = Self.fraction(segment, in: hours)
        let w = max(0, CGFloat(f.width) * width - UIMetrics.trackerSegmentGap)
        let revealed = reveal?.revealed ?? true
        return segmentBody(segment)
            .frame(width: w, height: height - UIMetrics.trackerSegmentInset * 2)
            .scaleEffect(x: revealed ? 1 : 0.001, anchor: .leading)
            .animation(animation(index), value: revealed)
            .offset(x: CGFloat(f.start) * width)
            .accessibilityLabel(Text(verbatim: label(segment)))
    }

    private func animation(_ index: Int) -> Animation? {
        guard let reveal else { return nil }
        return .easeOut(duration: reveal.grow).delay(Double(index) * reveal.stagger)
    }

    @ViewBuilder
    private func segmentBody(_ segment: ActivitySegment) -> some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerSegmentRadius, style: .continuous)
        if segment.kind == .notLogged {
            shape.strokeBorder(
                Night.trackerNotLogged,
                style: StrokeStyle(lineWidth: UIMetrics.cardBorder, dash: UIMetrics.trackerNotLoggedDash)
            )
        } else {
            shape.fill(ActivityColors.color(segment, in: categories))
                .overlay(alignment: .leading) {
                    if showsLabels, segment.length >= TimeInterval(UIMetrics.trackerSegmentLabelMinutes) * Timing.minute {
                        Text(verbatim: label(segment))
                            .font(Typography.hint)
                            .foregroundStyle(Night.onAccent)
                            .lineLimit(1)
                            .padding(.horizontal, UIMetrics.trackerSegmentInset)
                    }
                }
        }
    }

    private func label(_ segment: ActivitySegment) -> String {
        switch segment.kind {
        case .work: return segment.activity?.text ?? ""
        case .away: return Copywriter.trackerAwayText(segment.activity?.awayPlace)
        case .notLogged: return Copywriter.trackerNotLogged
        }
    }
}
