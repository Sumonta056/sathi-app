import SwiftUI

struct WaterInk {
    var glass: Color
    var water: Color
    var drained: Color
    var outline: Color
    var cap: Color

    static let day = WaterInk(
        glass: BuddyInk.waterGlass,
        water: BuddyInk.water,
        drained: BuddyInk.waterDrained,
        outline: BuddyInk.outline,
        cap: BuddyInk.waterDeep
    )

    static let night = WaterInk(
        glass: Night.heroFill(.water),
        water: Night.water,
        drained: Night.water.opacity(UIMetrics.drainedOpacity),
        outline: Night.waterLine,
        cap: Night.water
    )
}
