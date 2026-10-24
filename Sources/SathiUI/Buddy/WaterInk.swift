import SwiftUI

struct WaterInk {
    var glass: Color
    var water: Color
    var drained: Color
    var outline: Color
    var cap: Color

    static let day = WaterInk(
        glass: Palette.waterGlass,
        water: Palette.water,
        drained: Palette.waterDrained,
        outline: Palette.outline,
        cap: Palette.waterDeep
    )

    static let night = WaterInk(
        glass: Night.heroFill(.water),
        water: Night.water,
        drained: Night.water.opacity(UIMetrics.drainedOpacity),
        outline: Night.waterLine,
        cap: Night.water
    )
}
