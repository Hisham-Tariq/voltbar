import AppKit

// Generates the Voltbar app icon as a macOS .iconset (green squircle + white bolt),
// matching the About tile and site favicon. Run, then `iconutil -c icns`.

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

func makeIcon(px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!
    ctx.shouldAntialias = true

    // macOS-style squircle with margin.
    let inset = s * 0.085
    let rect = NSRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = rect.width * 0.2237
    let squircle = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    // Green vertical gradient fill.
    let grad = NSGradient(colors: [color(0x52E88B), color(0x34B866)])!
    grad.draw(in: squircle, angle: -90)

    // Subtle top sheen.
    let sheen = NSGradient(colors: [NSColor.white.withAlphaComponent(0.18), NSColor.clear])!
    sheen.draw(in: squircle, angle: -90)

    // White lightning bolt, centered.
    let cx = rect.midX, cy = rect.midY
    let h = rect.height * 0.30
    let w = rect.width * 0.20
    let bolt = NSBezierPath()
    bolt.move(to: NSPoint(x: cx + w * 0.45, y: cy + h))
    bolt.line(to: NSPoint(x: cx - w, y: cy - h * 0.10))
    bolt.line(to: NSPoint(x: cx - w * 0.05, y: cy - h * 0.10))
    bolt.line(to: NSPoint(x: cx - w * 0.45, y: cy - h))
    bolt.line(to: NSPoint(x: cx + w, y: cy + h * 0.10))
    bolt.line(to: NSPoint(x: cx + w * 0.05, y: cy + h * 0.10))
    bolt.close()
    NSColor.black.withAlphaComponent(0.12).setStroke()
    bolt.lineWidth = s * 0.01
    bolt.stroke()
    NSColor.white.setFill()
    bolt.fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "/tmp/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)

// (filename, pixel size)
let specs: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, px) in specs {
    let data = makeIcon(px: px)
    try! data.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}
print("wrote iconset to \(out)")
