import SathiCore
import SwiftUI

struct WelcomePlaces: View {
    let state: TrackerPromptState
    @ObservedObject var form: WelcomeForm

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerPlaceBoxSpacing) {
            WelcomeStep(number: 1, text: Copywriter.trackerWhereWereYou)
            TrackerFlowLayout(spacing: UIMetrics.trackerChipSpacing) {
                ForEach(AwayPlace.choices, id: \.self) { place in
                    chip(
                        Copywriter.trackerAwayPlace(place),
                        on: form.place == place && form.placeName == nil,
                        id: "tracker.place." + place.rawValue
                    ) {
                        form.pick(place)
                        state.actions.pickPlace(place)
                    }
                }
                ForEach(form.places, id: \.self) { name in
                    chip(name, on: form.placeName == name, id: "tracker.place.custom." + name) {
                        form.pick(named: name)
                        state.actions.pickPlaceName(name)
                    }
                }
                if !form.adding, form.places.count < Limits.awayPlaceMax { WelcomeAddChip { form.adding = true } }
            }
            if form.adding { WelcomeAddField(form: form, onSave: save) }
            if let away = state.away { saved(away) }
        }
        .trackerBox(padding: UIMetrics.trackerPlaceBoxPadding, radius: UIMetrics.trackerPlaceBoxRadius)
    }

    private func chip(_ label: String, on: Bool, id: String, action: @escaping () -> Void) -> some View {
        TrackerChip(label: label, on: on, id: id, font: UIMetrics.trackerPlaceFont, action: action)
    }

    private func saved(_ away: AwaySpan) -> some View {
        HStack(spacing: UIMetrics.trackerTitleDotGap) {
            Circle().fill(Night.trackerAway).frame(width: UIMetrics.trackerDot, height: UIMetrics.trackerDot)
            Text(verbatim: Copywriter.trackerAwaySaved(away.start, away.end, place: form.label, calendar: state.calendar))
                .font(Typography.tracker(UIMetrics.trackerPillFont, .semibold))
                .foregroundStyle(Night.chipText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func save() {
        guard let added = form.save() else { return }
        state.actions.addPlace(added)
    }
}

struct WelcomeAddChip: View {
    let action: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerPillHeight / 2, style: .circular)
        Button(action: action) {
            HStack(spacing: UIMetrics.trackerChipSpacing) {
                Image(systemName: "plus").font(.system(size: UIMetrics.trackerRemoveIcon, weight: .bold))
                Text(verbatim: Copywriter.trackerAddPlace).font(Typography.tracker(UIMetrics.trackerPlaceFont, .semibold))
            }
            .foregroundStyle(Night.muted)
            .padding(.horizontal, UIMetrics.trackerPillPadding)
            .frame(height: UIMetrics.trackerPillHeight)
            .overlay(shape.strokeBorder(Night.faint, style: StrokeStyle(lineWidth: UIMetrics.trackerChipBorder, dash: UIMetrics.trackerAddDash)))
            .contentShape(shape)
            .accessibilityIdentifier("tracker.place.add")
        }
        .buttonStyle(.plain)
    }
}

struct WelcomeAddField: View {
    @ObservedObject var form: WelcomeForm
    let onSave: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: UIMetrics.trackerPlaceFieldRadius, style: .continuous)
        HStack(spacing: UIMetrics.trackerButtonSpacing) {
            LazyTextField(placeholder: Copywriter.trackerNewPlace, text: $form.newName, startsEditing: true, onSubmit: onSave)
                .modifier(QuickTextLimit(text: $form.newName, limit: Limits.awayPlaceNameMax))
                .padding(.horizontal, TrackerSize.corner.fieldPadding)
                .frame(height: UIMetrics.trackerPlaceFieldHeight)
                .background(shape.fill(Night.bg))
                .overlay(shape.strokeBorder(Night.tracker, lineWidth: UIMetrics.trackerFieldBorder))
            TrackerPrimaryButton(
                label: Copywriter.trackerAddPlace, id: "tracker.place.save", height: UIMetrics.trackerPlaceFieldHeight,
                radius: UIMetrics.trackerPlaceFieldRadius, font: UIMetrics.trackerPlaceFont, action: onSave
            )
            .frame(width: UIMetrics.trackerPlaceSaveWidth)
        }
        TrackerHint(text: Copywriter.trackerPlaceKept)
    }
}
