import SathiCore
import SwiftUI

struct CalendarDayCard: View {
    let laid: CalendarLaidBlock
    let size: CGSize
    let calendar: Calendar
    let categories: [ActivityCategory]
    let calendarName: String?
    var edit: () -> Void = {}

    var body: some View {
        Text(verbatim: laid.block.title)
            .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}
