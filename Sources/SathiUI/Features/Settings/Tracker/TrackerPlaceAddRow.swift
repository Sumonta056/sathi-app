import SathiCore
import SwiftUI

struct TrackerPlaceAddRow: View {
    @EnvironmentObject var e: Engine
    @Binding var text: String

    var body: some View {
        HStack(spacing: UIMetrics.trackerPlaceAddGap) {
            LazyTextField(placeholder: Copywriter.trackerNewPlace, text: $text, onSubmit: add)
                .modifier(QuickTextLimit(text: $text, limit: Limits.awayPlaceNameMax))
                .frame(width: UIMetrics.trackerPlaceFieldWidth)
            Button(action: add) {
                Text(verbatim: Copywriter.trackerPlacesAdd)
            }
            .buttonStyle(AccentButton(accent: Night.tracker, height: UIMetrics.chipHeight))
            .accessibilityIdentifier("settings.tracker.place.add")
        }
    }

    private func add() {
        if e.addAwayPlace(text, tagsLastAway: false) { text = "" }
    }
}
