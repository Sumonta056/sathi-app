import SathiCore
import SwiftUI

enum SidebarSettingsStyle {
    static func icon(_ page: SettingsPage) -> String {
        switch page {
        case .general: return "slider.horizontal.3"
        case let .habit(id): return habitIcon(id)
        case .quickReminders: return "bell"
        case .tracker: return "waveform.path.ecg"
        case .timeBlocks: return "timer"
        case .sound: return "speaker.wave.2"
        }
    }

    static func tint(_ page: SettingsPage) -> Color {
        switch page {
        case let .habit(id): return Night.accent(id)
        case .quickReminders: return Night.quick
        case .tracker: return Night.tracker
        case .timeBlocks: return Night.block
        case .general, .sound: return Night.text
        }
    }

    static func fill(_ page: SettingsPage) -> Color {
        switch page {
        case .general, .sound: return Night.navSelected
        default: return tint(page).opacity(UIMetrics.sidebarTileFill)
        }
    }

    private static func habitIcon(_ id: HabitID) -> String {
        switch id {
        case .water: return "drop"
        case .reading: return "book"
        case .meditation: return "circle.circle"
        case .gym: return "dumbbell"
        }
    }
}

struct SidebarTile: View {
    let page: SettingsPage
    let size: CGFloat
    let iconSize: CGFloat
    var outlined = false

    var body: some View {
        Image(systemName: SidebarSettingsStyle.icon(page))
            .font(.system(size: iconSize, weight: .bold))
            .foregroundStyle(SidebarSettingsStyle.tint(page))
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: UIMetrics.sidebarTileRadius, style: .continuous).fill(SidebarSettingsStyle.fill(page)))
            .overlay {
                if outlined {
                    RoundedRectangle(cornerRadius: UIMetrics.sidebarTileRadius, style: .continuous)
                        .stroke(SidebarSettingsStyle.tint(page), lineWidth: UIMetrics.sidebarTileOutline)
                }
            }
    }
}
