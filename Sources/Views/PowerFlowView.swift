import SwiftUI

/// Power-flow diagram. Three layouts:
///  - Charging: adapter → split into (power into battery) + (power to laptop), with a
///    battery destination block and a laptop destination block.
///  - Plugged in, not charging: adapter → system → laptop (single flow).
///  - On battery: battery → system → laptop (single flow).
/// Shimmer animation runs only while the panel is visible.
struct PowerFlowView: View {
    let snap: BatterySnapshot
    @State private var phase: CGFloat = 0
    @Environment(\.panelVisible) private var panelVisible

    var body: some View {
        VStack(spacing: 10) {
            header
            if snap.isCharging {
                chargingFlow
            } else {
                simpleFlow
            }
            statusLine
            Text(snap.usageHint)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
        }
        .onChange(of: panelVisible) { _, vis in if vis { startShimmer() } else { phase = 0 } }
        .onAppear { if panelVisible { startShimmer() } }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 12))
            Text("Power Flow").font(.system(size: 14, weight: .semibold))
            Spacer()
        }
        .foregroundStyle(Theme.textSecondary)
    }

    // MARK: Charging — split flow with two destinations

    private var chargingFlow: some View {
        HStack(spacing: 10) {
            sourceBlock(icon: "powerplug.fill",
                        label: "\(Int(snap.adapterInputWatts.rounded()))W",
                        iconTint: Theme.green)
                .frame(width: 58)

            WaveSplitView(chargeWatts: snap.chargeWatts,
                          systemWatts: snap.systemLoadWatts,
                          phase: phase,
                          animated: panelVisible)
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                destBlock(icon: "battery.100.bolt", tint: Theme.green)
                destBlock(icon: "laptopcomputer", tint: Theme.textSecondary)
            }
            .frame(width: 58)
        }
        .frame(height: 116)
    }

    // MARK: Single flow (on battery, or plugged-not-charging)

    private var simpleFlow: some View {
        HStack(spacing: 10) {
            if snap.isACAttached {
                sourceBlock(icon: "powerplug.fill",
                            label: "\(Int(snap.adapterInputWatts.rounded()))W",
                            iconTint: Theme.green).frame(width: 58)
            } else {
                sourceBlock(icon: "battery.50", label: "Batt",
                            iconTint: Theme.textPrimary).frame(width: 58)
            }

            flowCell(text: String(format: "%.1f W", snap.systemLoadWatts),
                     tint: Color.white.opacity(0.06), bold: true, animated: true, big: true)

            destBlock(icon: "laptopcomputer", tint: Theme.textSecondary).frame(width: 58)
        }
        .frame(height: 96)
    }

    // MARK: Status line + components

    private var statusLine: some View {
        HStack(spacing: 6) {
            if snap.isCharging {
                Image(systemName: "bolt.fill").font(.system(size: 12)).foregroundStyle(Theme.green)
                Text("Charging at \(Int(snap.chargeWatts.rounded())) W")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.textPrimary)
            } else if snap.isACAttached {
                Image(systemName: "leaf.fill").font(.system(size: 12)).foregroundStyle(Theme.green)
                Text(snap.isFullyCharged ? "Fully Charged" : "Optimized Charging")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textPrimary)
            } else {
                Image(systemName: "battery.25").font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                Text("On battery • \(Int(snap.systemLoadWatts.rounded())) W")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(Theme.textPrimary)
            }
        }
    }

    private func sourceBlock(icon: String, label: String, iconTint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.04))
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(iconTint)
                Text(label).font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func destBlock(icon: String, tint: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.04))
            Image(systemName: icon).font(.system(size: 18, weight: .regular)).foregroundStyle(tint)
        }
    }

    private func flowCell(text: String, tint: Color, bold: Bool,
                          animated: Bool, big: Bool = false) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint)
            if animated {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient(colors: [.clear, Theme.green.opacity(0.16), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .offset(x: phase)
                    .opacity(panelVisible ? 1 : 0)
            }
            Text(text)
                .font(.system(size: big ? 17 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func startShimmer() {
        phase = -110
        withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) { phase = 110 }
    }
}

/// Dynamic curved split: one rounded container divided by a smooth S-curve whose position
/// reflects the charge/system power ratio. Top (green) = power into battery, bottom (gray) =
/// power to the laptop. Mirrors the real app's flowing design.
struct WaveSplitView: View {
    let chargeWatts: Double
    let systemWatts: Double
    let phase: CGFloat
    let animated: Bool

    /// Fraction of the height given to the top (battery) region.
    private var topFraction: CGFloat {
        let total = chargeWatts + systemWatts
        guard total > 0.1 else { return 0.5 }
        return CGFloat(max(0.18, min(0.82, chargeWatts / total)))
    }

    var body: some View {
        ZStack {
            // Bottom (laptop) region fills the whole container.
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Color(white: 0.42), Color(white: 0.28)],
                                     startPoint: .top, endPoint: .bottom))

            // Top (battery) region clipped by the wave boundary.
            WaveTopShape(topFraction: topFraction)
                .fill(LinearGradient(colors: [Theme.green.opacity(0.95), Theme.greenDim.opacity(0.85)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))

            // Subtle moving sheen while visible.
            if animated {
                WaveTopShape(topFraction: topFraction)
                    .fill(LinearGradient(colors: [.clear, .white.opacity(0.12), .clear],
                                         startPoint: .leading, endPoint: .trailing))
                    .offset(x: phase)
            }

            // Watt labels positioned within each region.
            GeometryReader { geo in
                let h = geo.size.height
                Text(String(format: "%.1f W", chargeWatts))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: geo.size.width, height: h * topFraction)
                    .position(x: geo.size.width / 2, y: h * topFraction / 2)
                Text(String(format: "%.1f W", systemWatts))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: geo.size.width, height: h * (1 - topFraction))
                    .position(x: geo.size.width / 2, y: h * topFraction + h * (1 - topFraction) / 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeInOut(duration: 0.5), value: topFraction)
    }
}

/// Filled top region with a smooth S-curve lower boundary.
struct WaveTopShape: Shape {
    var topFraction: CGFloat

    var animatableData: CGFloat {
        get { topFraction }
        set { topFraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let baseY = h * topFraction
        let amp = max(6, h * 0.13)
        let yL = baseY - amp          // boundary height at the left edge
        let yR = baseY + amp          // boundary height at the right edge

        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w, y: 0))
        p.addLine(to: CGPoint(x: w, y: yR))
        // S-curve back across to the left edge.
        p.addCurve(to: CGPoint(x: 0, y: yL),
                   control1: CGPoint(x: w * 0.62, y: yR),
                   control2: CGPoint(x: w * 0.38, y: yL))
        p.closeSubpath()
        return p
    }
}

// Environment flag so child animations stop when the panel closes.
private struct PanelVisibleKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues {
    var panelVisible: Bool {
        get { self[PanelVisibleKey.self] }
        set { self[PanelVisibleKey.self] = newValue }
    }
}
