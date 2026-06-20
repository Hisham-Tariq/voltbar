import AppKit

/// Renders the menu-bar glyph to match the real app: a color-coded battery pill with the
/// percentage NUMBER inside, plus a bolt when charging. Drawn once per power-source change.
enum MenuBarIcon {

    static func image(for snap: BatterySnapshot) -> NSImage {
        let height: CGFloat = 15
        let bodyHeight: CGFloat = 14
        let capWidth: CGFloat = 1.6
        let capGap: CGFloat = 1.3
        let pad: CGFloat = 4.5            // inner horizontal padding around contents
        let boltW: CGFloat = snap.isCharging ? 6.0 : 0
        let boltGap: CGFloat = snap.isCharging ? 1.5 : 0

        // Filled green pill ONLY when on power (charging or plugged in).
        // On battery → translucent battery outline with the number, color-coded by level.
        let onPower = snap.isCharging || snap.isACAttached
        let accent = accentColor(for: snap)
        let textColor: NSColor = onPower ? .white : accent

        let text = "\(max(0, min(100, snap.percent)))"
        let font = NSFont.systemFont(ofSize: 10, weight: .bold)
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
        ]
        let textSize = (text as NSString).size(withAttributes: textAttrs)

        let bodyWidth = pad + ceil(textSize.width) + boltGap + boltW + pad
        let width = bodyWidth + capGap + capWidth + 1

        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        defer { image.unlockFocus() }
        NSGraphicsContext.current?.shouldAntialias = true

        let bodyRect = NSRect(x: 0.5, y: (height - bodyHeight) / 2, width: bodyWidth, height: bodyHeight)
        let body = NSBezierPath(roundedRect: bodyRect, xRadius: 3.5, yRadius: 3.5)
        let capRect = NSRect(x: bodyRect.maxX + capGap, y: bodyRect.midY - 2.6,
                             width: capWidth, height: 5.2)
        let cap = NSBezierPath(roundedRect: capRect, xRadius: 0.8, yRadius: 0.8)

        if onPower {
            // Filled pill.
            accent.setFill(); body.fill()
            accent.withAlphaComponent(0.9).setFill(); cap.fill()
            NSColor.white.withAlphaComponent(0.22).setStroke()
            body.lineWidth = 1; body.stroke()
        } else {
            // Outline only.
            accent.withAlphaComponent(0.95).setStroke()
            body.lineWidth = 1.3; body.stroke()
            accent.withAlphaComponent(0.95).setFill(); cap.fill()
        }

        // Contents: percentage number, then bolt if charging.
        let contentW = textSize.width + boltGap + boltW
        var x = bodyRect.minX + (bodyRect.width - contentW) / 2
        let textY = bodyRect.midY - textSize.height / 2
        (text as NSString).draw(at: NSPoint(x: x, y: textY), withAttributes: textAttrs)
        x += textSize.width + boltGap
        if snap.isCharging {
            drawBolt(at: NSRect(x: x, y: bodyRect.minY + 2, width: boltW, height: bodyRect.height - 4),
                     color: .white)
        }

        image.isTemplate = false
        return image
    }

    private static func accentColor(for snap: BatterySnapshot) -> NSColor {
        let green = NSColor(srgbRed: 0.24, green: 0.78, blue: 0.45, alpha: 1)
        if snap.isCharging || snap.isACAttached { return green }
        switch snap.percent {
        case 20...:   return NSColor.white       // normal on-battery: clean white outline
        case 10..<20: return NSColor.systemOrange
        default:      return NSColor.systemRed
        }
    }

    private static func drawBolt(at rect: NSRect, color: NSColor) {
        let cx = rect.midX, cy = rect.midY
        let h = rect.height * 0.5, w = rect.width * 0.42
        let bolt = NSBezierPath()
        bolt.move(to: NSPoint(x: cx + w * 0.35, y: cy + h))
        bolt.line(to: NSPoint(x: cx - w, y: cy + h * 0.05))
        bolt.line(to: NSPoint(x: cx - w * 0.05, y: cy + h * 0.05))
        bolt.line(to: NSPoint(x: cx - w * 0.35, y: cy - h))
        bolt.line(to: NSPoint(x: cx + w, y: cy - h * 0.05))
        bolt.line(to: NSPoint(x: cx + w * 0.05, y: cy - h * 0.05))
        bolt.close()
        color.setFill(); bolt.fill()
    }
}
