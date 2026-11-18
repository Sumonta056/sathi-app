import SathiCore
import SwiftUI

@MainActor
enum CalendarLaneMemory {
    typealias Shapes = [ReportRange: Set<CalendarLaneShape>]

    static var remembered: Shapes = [:]

    static func narrow(_ shapes: Shapes, for kind: ReportRange) -> Set<CalendarLaneShape> {
        shapes[kind] ?? []
    }

    static func next(_ current: Shapes, kind: ReportRange, columnWidth: CGFloat) -> Shapes? {
        let shapes = CalendarNarrowLanes.shapes(columnWidth: columnWidth)
        guard narrow(current, for: kind) != shapes else { return nil }
        var all = current
        all[kind] = shapes
        return all
    }
}
