import AppKit
import SwiftUI
import ViewInspector

final class Box<Value> {
    var value: Value
    init(_ value: Value) { self.value = value }

    var binding: Binding<Value> {
        Binding(get: { self.value }, set: { self.value = $0 })
    }
}

struct RGB: Equatable {
    let r: Double
    let g: Double
    let b: Double

    init(hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }

    init(_ color: Color) {
        let c = NSColor(color).usingColorSpace(.sRGB) ?? .black
        r = Double(c.redComponent)
        g = Double(c.greenComponent)
        b = Double(c.blueComponent)
    }

    func matches(_ other: RGB) -> Bool {
        let tolerance = 1.0 / 255
        return abs(r - other.r) <= tolerance && abs(g - other.g) <= tolerance && abs(b - other.b) <= tolerance
    }

    var luminance: Double {
        func channel(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }
}

enum Contrast {
    static func ratio(_ a: Color, _ b: Color) -> Double {
        let la = RGB(a).luminance
        let lb = RGB(b).luminance
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}

@MainActor
enum A11y {
    static func isSelected(_ view: InspectableView<some BaseViewType>) -> Bool {
        if (try? view.accessibilityTraits().contains(.isSelected)) == true { return true }
        return !view.findAll(where: { try $0.accessibilityTraits().contains(.isSelected) }).isEmpty
    }
}
