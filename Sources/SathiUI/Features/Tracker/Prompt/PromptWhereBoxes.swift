import SathiCore
import SwiftUI

struct PromptWhereBoxes: View {
    let state: TrackerPromptState
    @ObservedObject var form: PromptWhereForm
    let showsIWasHere: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.promptWhereGap) {
            PromptBoxes {
                Text(verbatim: Copywriter.trackerWhereWereYou)
                    .font(Typography.tracker(UIMetrics.promptWhereFont, .medium))
                    .foregroundStyle(Night.sproutLight)
                    .frame(height: UIMetrics.promptWhereHeight)
                ForEach(AwayPlace.choices, id: \.self) { place in
                    box(Copywriter.trackerAwayPlace(place), on: form.place == place && form.placeName == nil, id: "tracker.place." + place.rawValue) {
                        form.pick(place)
                        state.actions.pickPlace(place)
                    }
                }
                ForEach(form.places, id: \.self) { name in
                    box(name, on: form.placeName == name, id: "tracker.place.custom." + name) {
                        form.pick(named: name)
                        state.actions.pickPlaceName(name)
                    }
                }
                if !form.adding, form.places.count < Limits.awayPlaceMax {
                    box(Copywriter.activityPromptAddPlace, on: false, id: "tracker.place.add") { form.adding = true }
                }
                if showsIWasHere {
                    box(Copywriter.trackerIWasHere, on: false, id: "tracker.here") { state.actions.iWasHere() }
                }
            }
            if form.adding { addField }
            ForEach(state.loggedWhileAway, id: \.id) { row($0) }
        }
        .padding(.top, UIMetrics.promptWhereGap)
    }

    private func box(_ label: String, on: Bool, id: String, action: @escaping () -> Void) -> some View {
        PromptBox(label: label, on: on, id: id, look: .place, action: action)
    }

    private var addField: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.promptBoxRadius, style: .continuous)
        return HStack(spacing: UIMetrics.promptWhereGap) {
            LazyTextField(placeholder: Copywriter.trackerNewPlace, text: $form.newName, startsEditing: true, onSubmit: save)
                .modifier(QuickTextLimit(text: $form.newName, limit: Limits.awayPlaceNameMax))
                .frame(width: UIMetrics.promptPlaceFieldWidth, height: UIMetrics.promptBoxHeight)
                .background(shape.fill(Night.promptBox))
                .overlay(shape.strokeBorder(Night.promptBack, lineWidth: UIMetrics.promptBorder))
            box(Copywriter.trackerAddPlace, on: true, id: "tracker.place.save", action: save)
        }
    }

    private func row(_ a: Activity) -> some View {
        HStack(spacing: UIMetrics.promptWhereGap) {
            Text(verbatim: a.text)
                .font(Typography.tracker(UIMetrics.promptWhereFont, .bold))
                .foregroundStyle(Night.text)
            Text(verbatim: Copywriter.trackerSpan(a.start, a.end, calendar: state.calendar) + " · " + Copywriter.trackerLogged)
                .font(Typography.tracker(UIMetrics.promptWhereFont, .medium))
                .foregroundStyle(Night.muted)
            if let eventID = a.sourceEventID {
                box(Copywriter.trackerNotAttending, on: false, id: "tracker.notAttending") { state.actions.notAttending(eventID) }
            }
        }
    }

    private func save() {
        guard let added = form.save() else { return }
        state.actions.addPlace(added)
    }
}
