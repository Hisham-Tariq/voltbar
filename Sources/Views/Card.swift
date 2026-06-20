import SwiftUI

/// Rounded translucent card container used by every section.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .fill(Theme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            )
    }
}

/// Small solid circular status badge (white glyph on a filled circle), as in the real app.
struct StatusBadge: View {
    var systemName: String
    var color: Color
    var size: CGFloat = 23

    var body: some View {
        ZStack {
            Circle().fill(color)
            Image(systemName: systemName)
                .font(.system(size: size * 0.52, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

/// Full-width hairline used to separate sections inside a unified card.
struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1)
            .padding(.vertical, 2)
    }
}

/// Info "i" affordance in card corners.
struct InfoDot: View {
    var body: some View {
        Image(systemName: "info.circle")
            .font(.system(size: 15, weight: .regular))
            .foregroundStyle(Theme.textTertiary)
    }
}
