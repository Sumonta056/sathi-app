import SathiCore
import SwiftUI

package struct StatusLabel: View {
    @ObservedObject var status: StatusModel

    package init(status: StatusModel) {
        self.status = status
    }

    package var body: some View {
        HStack(spacing: 4) {
            if status.isBook {
                Image(systemName: "book.closed.fill")
            } else {
                Image(nsImage: StatusIcon.image(level: status.iconLevel))
            }
            Text(status.text).monospacedDigit()
        }
    }
}
