import SwiftUI

// These are SECTIONS (content only, no Card wrapper). BatteryInformationCard
// stacks them inside one continuous card separated by hairline dividers,
// matching the real app's layout.

// MARK: - Battery Health

struct BatteryHealthSection: View {
    let snap: BatterySnapshot
    private var color: Color { Theme.levelColor(snap.healthPercent) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusBadge(systemName: "checkmark", color: color)
                Text("Battery Health")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                InfoDot()
            }
            HStack(alignment: .firstTextBaseline) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(snap.healthPercent)%")
                        .font(.system(size: 21, weight: .heavy, design: .rounded))
                        .foregroundStyle(color)
                    Text(snap.healthStatus)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(color.opacity(0.75))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(snap.cycleCount)/1000")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Cycle Count")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            ProgressBar(fraction: min(1.0, Double(snap.healthPercent) / 100.0), color: color)
                .frame(height: 7)
        }
    }
}

// MARK: - Temperature

struct TemperatureSection: View {
    let snap: BatterySnapshot
    private var color: Color { snap.temperatureIsNormal ? Theme.green : Theme.orange }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusBadge(systemName: "thermometer.medium", color: color)
                Text("Temperature")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                InfoDot()
            }
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f°C", snap.temperatureC))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text(String(format: "%.1f°F", snap.temperatureF))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(color)
                        Text(snap.temperatureStatus)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text(snap.temperatureIsNormal ? "Optimal performance" : "Elevated")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}

// MARK: - Power & Electrical (+ Power Flow)

struct PowerElectricalSection: View {
    let snap: BatterySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                StatusBadge(systemName: "bolt.fill", color: Theme.orange)
                Text("Power & Electrical")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                InfoDot()
            }

            HStack(alignment: .top) {
                metric(title: "Power Usage",
                       value: String(format: "%.1f", snap.powerUsageWatts), unit: "W")
                Spacer()
                metric(title: "Voltage",
                       value: String(format: "%.2f", snap.voltage), unit: "V",
                       alignment: .trailing)
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 4) {
                        Text("\(snap.amperage)").font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                        Text("mA").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.unit)
                        Image(systemName: snap.amperage > 0 ? "arrow.up.circle" : "arrow.down.circle")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: snap.isCharging ? "bolt.fill" : "pause.fill").font(.system(size: 11))
                        Text(snap.currentLabel).font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(Theme.textPrimary)
                    Text("Normal voltage").font(.system(size: 12)).foregroundStyle(Theme.green)
                }
            }

            PowerFlowView(snap: snap)
        }
    }

    private func metric(title: String, value: String, unit: String,
                        alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.unit)
            }
        }
    }
}

// MARK: - Capacity Details

struct CapacityDetailsSection: View {
    let snap: BatterySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "battery.100")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.blue)
                Text("Capacity Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                InfoDot()
            }
            row("Remaining", snap.currentCapacity, color: Theme.green)
            row("Current Full", snap.maxCapacity, color: Theme.blue)
            row("Design Capacity", snap.designCapacity, color: Theme.textSecondary)
        }
    }

    private func row(_ label: String, _ mAh: Int, color: Color) -> some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(Theme.textPrimary)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(mAh.formatted())")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                Text("mAh").font(.system(size: 12, weight: .medium)).foregroundStyle(color.opacity(0.85))
            }
        }
    }
}
