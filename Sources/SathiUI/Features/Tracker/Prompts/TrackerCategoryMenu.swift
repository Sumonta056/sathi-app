import SathiCore
import SwiftUI

struct TrackerCategoryMenu: View {
    let categories: [ActivityCategory]
    let selected: String?
    let idPrefix: String
    var allowsNone = true
    var compact = false
    var fill = Night.card
    var fixedWidth: CGFloat?
    let onPick: (String?) -> Void
    @State private var isOpen = false

    var body: some View {
        let size = TrackerSize.of(compact: compact)
        let shape = RoundedRectangle(cornerRadius: size.dropRadius, style: .continuous)
        Button { isOpen.toggle() } label: {
            HStack(spacing: size.dropGap) {
                if let hex = categories.first(where: { $0.name == selected })?.colorHex {
                    Circle().fill(Color(hex: hex)).frame(width: size.dot, height: size.dot)
                }
                Text(verbatim: selected ?? Copywriter.trackerNoCategory)
                    .font(Typography.tracker(size.label, .bold))
                    .foregroundStyle(selected == nil ? Night.muted : Night.text)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                TrackerChevron(size: size.chevron)
            }
            .padding(.horizontal, size.dropPadding)
            .frame(height: size.dropHeight)
            .frame(maxWidth: fixedWidth ?? .infinity)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(isOpen ? Night.tracker : Night.fieldBorder, lineWidth: UIMetrics.cardBorder))
            .contentShape(shape)
            .accessibilityIdentifier(idPrefix + "menu")
        }
        .buttonStyle(TrackerPressStyle())
        .accessibilityLabel(Text(verbatim: Copywriter.trackerCategory))
        .accessibilityValue(Text(verbatim: selected ?? Copywriter.trackerNoCategory))
        .popover(isPresented: $isOpen, arrowEdge: .bottom) { list }
    }

    var list: TrackerCategoryList {
        TrackerCategoryList(categories: categories, selected: selected, idPrefix: idPrefix, allowsNone: allowsNone) {
            isOpen = false
            onPick($0)
        }
    }
}

struct TrackerCategoryList: View {
    let categories: [ActivityCategory]
    let selected: String?
    let idPrefix: String
    var allowsNone = true
    let onPick: (String?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UIMetrics.trackerDropRowGap) {
            ForEach(categories) { category in
                TrackerMenuRow(
                    label: category.name, id: idPrefix + category.name, dot: Color(hex: category.colorHex), selected: selected == category.name
                ) {
                    onPick(category.name)
                } trailing: {
                    if selected == category.name {
                        Text(verbatim: Copywriter.trackerCheck)
                            .font(Typography.tracker(UIMetrics.trackerDetailFont, .heavy))
                            .foregroundStyle(Night.tracker)
                    }
                }
            }
            if allowsNone {
                Rectangle().fill(Night.fieldBorder).frame(height: UIMetrics.cardBorder).padding(UIMetrics.trackerDropDividerPadding)
                TrackerMenuRow(
                    label: Copywriter.trackerNoCategory, id: idPrefix + "none", dashedDot: true, selected: false, color: Night.muted
                ) {
                    onPick(nil)
                } trailing: {
                    EmptyView()
                }
            }
        }
        .trackerMenuList(width: UIMetrics.trackerCategoryMenuWidth)
    }
}
