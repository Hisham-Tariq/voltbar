import AppKit

// Renders the menu-bar icon in several states to PNGs for visual verification.
func dump(_ snap: BatterySnapshot, _ name: String) {
    let img = MenuBarIcon.image(for: snap)
    // Render at 4x scale so the small glyph is inspectable.
    let scale: CGFloat = 8
    let px = NSSize(width: img.size.width * scale, height: img.size.height * scale)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(px.width),
                               pixelsHigh: Int(px.height), bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    // Dark backdrop to mimic a dark menu bar.
    NSColor(white: 0.12, alpha: 1).setFill()
    NSRect(origin: .zero, size: px).fill()
    img.draw(in: NSRect(origin: .zero, size: px))
    NSGraphicsContext.restoreGraphicsState()
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "/tmp/icon_\(name).png"))
    print("wrote /tmp/icon_\(name).png")
}

var charging = BatterySnapshot.placeholder
charging.hasBattery = true; charging.percent = 80; charging.isCharging = true; charging.isACAttached = true
dump(charging, "charging")

var acFull = BatterySnapshot.placeholder
acFull.hasBattery = true; acFull.percent = 80; acFull.isCharging = false; acFull.isACAttached = true
dump(acFull, "ac_notcharging")

var onBatt = BatterySnapshot.placeholder
onBatt.hasBattery = true; onBatt.percent = 75; onBatt.isCharging = false; onBatt.isACAttached = false
dump(onBatt, "onbattery")

var low = BatterySnapshot.placeholder
low.hasBattery = true; low.percent = 12; low.isCharging = false; low.isACAttached = false
dump(low, "low")
