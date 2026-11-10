import SathiCore
import SwiftUI

struct TrackerCategoryChip: View {
    let category: ActivityCategory
    @EnvironmentObject var e: Engine
    @State private var name = ""
    @State private var isOpen = false
    @FocusState private var focused: Bool

    var body: some View {
        let engine = e
        HStack(spacing: UIMetrics.chipSpacing) {
            Button { isOpen.toggle() } label: {
                Circle().fill(Color(hex: category.colorHex)).frame(width: UIMetrics.trackerSwatch, height: UIMetrics.trackerSwatch)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "Color of \(category.name)"))
            .popover(isPresented: $isOpen, arrowEdge: .bottom) { swatches }
            TextField("", text: $name)
                .textFieldStyle(.plain)
                .font(Typography.chip)
                .foregroundStyle(Night.text)
                .focused($focused)
                .fixedSize()
                .frame(minWidth: UIMetrics.trackerCalendarNameWidth)
                .onSubmit { commit() }
                .onChange(of: focused) { if !$0 { commit() } }
                .accessibilityLabel(Text(verbatim: category.name))
            Button { engine.removeTrackerCategory(category.name) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: UIMetrics.dayOffRemoveIconSize, weight: .heavy))
                    .foregroundStyle(Night.muted)
                    .frame(width: UIMetrics.trackerCategoryRemove, height: UIMetrics.trackerCategoryRemove)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: Copywriter.trackerRemoveCategory(category.name)))
        }
        .padding(UIMetrics.trackerCategoryChipPadding)
        .overlay(Pill().strokeBorder(Night.fieldBorder, lineWidth: UIMetrics.chipBorder))
        .onAppear { name = category.name }
        .onChange(of: category.name) { name = $0 }
    }

    private var swatches: some View {
        let engine = e
        return HStack(spacing: UIMetrics.trackerSwatchSpacing) {
            ForEach(ActivityCategory.palette, id: \.self) { hex in
                Button { Self.recolor(category.name, to: hex, in: engine) } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: UIMetrics.trackerSwatch, height: UIMetrics.trackerSwatch)
                        .overlay(Circle().strokeBorder(Night.text, lineWidth: hex == category.colorHex ? UIMetrics.chipBorder : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: String(hex, radix: 16)))
            }
        }
        .padding(UIMetrics.timePickerPadding)
        .background(Night.card)
        .environment(\.colorScheme, .dark)
    }

    private func commit() {
        if !Self.commit(rename: name, from: category.name, in: e) { name = category.name }
    }

    @discardableResult
    static func commit(rename name: String, from old: String, in engine: Engine) -> Bool {
        if name == old { return true }
        return engine.renameTrackerCategory(old, to: name)
    }

    static func recolor(_ name: String, to hex: UInt32, in engine: Engine) {
        engine.setActivityCategoryColor(name, colorHex: hex)
    }
}
