import SathiCore
import SwiftUI

struct PromptAwayRow: View {
    @ObservedObject var model: ActivityPromptModel
    @ObservedObject var form: PromptWhereForm
    let state: TrackerPromptState

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptWhereGap) {
            HStack(spacing: UIMetrics.promptFooterGap) {
                BuddySwitch(isOn: model.awaySwitch, accent: Night.sprout, label: Copywriter.activityPromptAwaySwitch)
                    .accessibilityIdentifier("tracker.away.toggle")
                Text(verbatim: Copywriter.activityPromptAwaySwitch)
                    .font(Typography.tracker(UIMetrics.promptRowFont, .medium))
                    .foregroundStyle(Night.chipText)
            }
            if model.awayOn { chips }
            if model.awayOn, model.awayAdding {
                PromptPlaceField(text: $model.awayNewName, saveID: "tracker.away.save", onSave: save)
            }
        }
    }

    private var chips: some View {
        PromptBoxes {
            ForEach(AwayPlace.choices.filter { $0 != .other }, id: \.self) { builtIn($0) }
            ForEach(form.places, id: \.self) { name in
                box(name, on: model.awayPick == PromptAwayPick(place: .other, name: name), id: "tracker.away.custom." + name) {
                    model.pickAway(named: name)
                }
            }
            builtIn(.other)
            if !model.awayAdding, form.places.count < Limits.awayPlaceMax {
                box(Copywriter.activityPromptAddPlace, on: false, id: "tracker.away.add") { model.awayAdding = true }
            }
        }
    }

    private func builtIn(_ place: AwayPlace) -> some View {
        box(
            Copywriter.trackerAwayPlace(place),
            on: model.awayPick == PromptAwayPick(place: place, name: nil),
            id: "tracker.away.place." + place.rawValue
        ) {
            model.pickAway(place)
        }
    }

    private func box(_ label: String, on: Bool, id: String, action: @escaping () -> Void) -> some View {
        PromptBox(label: label, on: on, id: id, look: .place, action: action)
    }

    private func save() {
        guard let added = model.saveAwayPlace() else { return }
        state.actions.addPlace(added)
    }
}
