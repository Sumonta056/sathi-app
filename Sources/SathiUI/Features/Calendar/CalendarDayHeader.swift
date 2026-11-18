import SathiCore
import SwiftUI

struct CalendarDayHeader: View {
    let blocks: [CalendarLaidBlock]
    let actualWidth: CGFloat

    var body: some View {
        EmptyView()
    }

    static func tracked(_ blocks: [CalendarLaidBlock]) -> TimeInterval { 0 }

    static func events(_ blocks: [CalendarLaidBlock]) -> Int { 0 }
}
