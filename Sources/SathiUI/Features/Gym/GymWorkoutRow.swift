import SathiCore
import SwiftUI

struct GymWorkoutRow: View {
    @EnvironmentObject var e: Engine
    let index: Int

    var body: some View {
        let engine = e
        let minutes = engine.gymWorkoutMinutes(at: index)
        HStack(alignment: .top, spacing: UIMetrics.chipSpacing) {
            number
            VStack(alignment: .leading, spacing: UIMetrics.sectionSpacing) {
                field(engine)
                chips(minutes)
            }
        }
        .padding(UIMetrics.rowPadding)
        .overlay(alignment: .top) {
            if index > 0 {
                Rectangle()
                    .fill(Night.divider)
                    .frame(height: UIMetrics.dividerHeight)
            }
        }
    }

    private var number: some View {
        Text(verbatim: "\(index + 1)")
            .font(Typography.chip)
            .foregroundStyle(Night.gym)
            .frame(width: UIMetrics.gymWorkoutNumberSize, height: UIMetrics.gymWorkoutNumberSize)
            .background(Circle().fill(Night.divider))
            .accessibilityHidden(true)
    }

    private func field(_ engine: Engine) -> some View {
        TextField("Workout \(index + 1)", text: engine.gymWorkoutName(at: index))
            .textFieldStyle(.plain)
            .font(Typography.chip)
            .foregroundStyle(Night.text)
            .padding(UIMetrics.timeButtonPadding)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: UIMetrics.buttonRadius, style: .continuous).fill(Night.bg))
    }

    private func chips(_ minutes: Binding<Int>) -> some View {
        ChipRow(
            options: Limits.gymWorkoutLengths,
            accent: Night.gym,
            isSelected: { $0 == minutes.wrappedValue },
            onTap: { minutes.wrappedValue = $0 },
            label: { "\($0) min" }
        )
        .fixedSize()
    }
}
