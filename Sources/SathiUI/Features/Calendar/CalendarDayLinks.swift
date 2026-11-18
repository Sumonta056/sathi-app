import SathiCore
import SwiftUI

struct CalendarDayLink: Identifiable {
    let id: String
    let color: Color
    let points: [CGPoint]
}

struct CalendarDayLinks: View {
    let blocks: [CalendarLaidBlock]
    let actualWidth: CGFloat
    let planX: CGFloat
    let colors: [String: Color]

    var body: some View {
        EmptyView()
    }

    static func links(blocks: [CalendarLaidBlock], actualWidth: CGFloat, planX: CGFloat, colors: [String: Color]) -> [CalendarDayLink] {
        []
    }

    static func points(activity: CalendarLaidBlock, event: CalendarLaidBlock, actualWidth: CGFloat, planX: CGFloat) -> [CGPoint] {
        []
    }
}
