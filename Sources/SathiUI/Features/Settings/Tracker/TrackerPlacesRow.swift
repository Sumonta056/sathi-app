import SathiCore
import SwiftUI

struct TrackerPlacesRow: View {
    @EnvironmentObject var e: Engine
    @State private var newName = ""

    var body: some View {
        let engine = e
        VStack(alignment: .leading, spacing: 0) {
            SettingRow(label: Copywriter.trackerPlacesLabel, hint: Copywriter.trackerPlacesHint) { EmptyView() }
            VStack(alignment: .leading, spacing: UIMetrics.trackerPlaceBoxSpacing) {
                group(Copywriter.trackerPlacesBuiltIn) {
                    ForEach(AwayPlace.choices, id: \.self) { place in
                        TrackerPlaceChip(name: Copywriter.trackerAwayPlace(place), remove: nil)
                    }
                }
                if !engine.awayPlaces.isEmpty {
                    group(Copywriter.trackerPlacesYours) {
                        ForEach(engine.awayPlaces, id: \.self) { name in
                            TrackerPlaceChip(name: name) { engine.removeAwayPlace(name) }
                        }
                    }
                }
                if engine.awayPlaces.count < Limits.awayPlaceMax {
                    TrackerPlaceAddRow(text: $newName)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(
                top: 0, leading: UIMetrics.rowPadding.leading,
                bottom: UIMetrics.rowPadding.bottom, trailing: UIMetrics.rowPadding.trailing
            ))
        }
    }

    private func group(_ title: String, @ViewBuilder chips: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerPlaceBoxSpacing) {
            Text(verbatim: title)
                .font(Typography.hint)
                .foregroundStyle(Night.faint)
            TrackerFlowLayout(spacing: UIMetrics.trackerChipSpacing) { chips() }
        }
    }
}
