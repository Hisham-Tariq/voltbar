import SwiftUI

/// Top hero card: big percentage, charging state, time-to-full/empty, progress bar.
struct HeaderCard: View {
    let snap: BatterySnapshot

    private var accent: Color {
        snap.isACAttached ? Theme.green : Theme.levelColor(snap.percent)
    }

    private var stateText: String {
        if snap.isFullyCharged { return "Charged" }
        if snap.isCharging { return "Charging" }
        if snap.isACAttached { return "Plugged In" }
        return "On Battery"
    }

    private var timeTitle: String {
        if snap.isCharging { return "UNTIL FULL" }
        if snap.isACAttached { return "PLUGGED IN" }
        return "UNTIL EMPTY"
    }

    private var timeValue: String {
        if snap.isFullyCharged { return "Full" }
        if snap.isCharging {
            return snap.bestTimeToFull.map(Self.fmt) ?? "Calculating…"
        }
        if snap.isACAttached { return "—" }
        return snap.bestTimeToEmpty.map(Self.fmt) ?? "Calculating…"
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(snap.percent)")
                                .font(.system(size: 35, weight: .heavy, design: .rounded))
                                .foregroundStyle(accent)
                            Text("%")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent.opacity(0.7))
                        }
                        HStack(spacing: 6) {
                            Image(systemName: snap.isCharging ? "bolt.fill"
                                  : (snap.isACAttached ? "powerplug.fill" : "battery.100"))
                                .foregroundStyle(snap.isCharging ? Theme.orange : accent)
                            Text(stateText)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(timeTitle)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .tracking(0.5)
                        Text(timeValue)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }

                ProgressBar(fraction: Double(snap.percent) / 100.0, color: accent)
                    .frame(height: 8)
            }
        }
    }

    private static func fmt(_ minutes: Int) -> String {
        if minutes <= 0 { return "—" }
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)m" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

/// Segmented rounded progress bar.
struct ProgressBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))
                Capsule()
                    .fill(color)
                    .frame(width: max(8, geo.size.width * max(0, min(1, fraction))))
            }
        }
    }
}
