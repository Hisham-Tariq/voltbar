import SwiftUI

/// Design tokens for the Voltbar battery panel.
enum Theme {
    // Colors
    static let green = Color(hex: 0x4ADE80)
    static let greenDim = Color(hex: 0x3FAE6A)
    static let blue = Color(hex: 0x3B82F6)
    static let orange = Color(hex: 0xF59E0B)
    static let red = Color(hex: 0xEF4444)
    static let gray = Color(hex: 0x8E8E93)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0x9A9AA0)
    static let textTertiary = Color(white: 1.0, opacity: 0.35)
    static let unit = Color(hex: 0xC7C7CC)          // brighter so W / V / mA read clearly

    static let cardFill = Color(white: 1.0, opacity: 0.05)
    static let cardStroke = Color(white: 1.0, opacity: 0.08)
    static let divider = Color(white: 1.0, opacity: 0.08)

    /// Very light scrim over the glass vibrancy — just enough to deepen contrast and tame
    /// the wallpaper tint, while keeping the translucent "glass" feel that adapts to whatever
    /// is behind the panel.
    static let panelScrim = Color(hex: 0x0D0E10, opacity: 0.28)

    // Geometry
    static let panelWidth: CGFloat = 328
    static let panelRadius: CGFloat = 18
    static let cardRadius: CGFloat = 14
    static let cardPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 10

    /// Status color from a 0...100+ health/charge percentage.
    static func levelColor(_ pct: Int) -> Color {
        switch pct {
        case 80...:   return green
        case 40..<80: return green
        case 20..<40: return orange
        default:      return red
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
