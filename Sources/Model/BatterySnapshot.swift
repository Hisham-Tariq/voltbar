import Foundation

/// Immutable value type holding every field the UI displays.
/// One IOKit read produces one snapshot; the UI binds only to the latest.
struct BatterySnapshot: Equatable {
    // Lightweight (power-source) fields — drive the menu-bar icon.
    var percent: Int                 // 0...100
    var isCharging: Bool
    var isACAttached: Bool
    var isFullyCharged: Bool
    var timeToFullMinutes: Int?      // nil = calculating / unknown
    var timeToEmptyMinutes: Int?

    // Detailed (AppleSmartBattery) fields — for the cards.
    var hasBattery: Bool
    var cycleCount: Int
    var designCapacity: Int          // mAh
    var maxCapacity: Int             // mAh (AppleRawMaxCapacity)
    var currentCapacity: Int         // mAh (AppleRawCurrentCapacity)
    var temperatureC: Double         // °C
    var voltage: Double              // V
    var amperage: Int                // mA, signed (negative = discharging)
    var adapterWatts: Int            // adapter rating, 0 if none
    var adapterName: String?
    var adapterPowerDraw: Double     // actual live adapter power (W), 0 if unknown
    var avgTimeToEmptyReg: Int?      // OS smoothed estimate (min) from AppleSmartBattery
    var avgTimeToFullReg: Int?       // OS smoothed estimate (min) from AppleSmartBattery

    var updated: Date

    static let placeholder = BatterySnapshot(
        percent: 0, isCharging: false, isACAttached: false, isFullyCharged: false,
        timeToFullMinutes: nil, timeToEmptyMinutes: nil,
        hasBattery: false, cycleCount: 0, designCapacity: 0, maxCapacity: 0,
        currentCapacity: 0, temperatureC: 0, voltage: 0, amperage: 0,
        adapterWatts: 0, adapterName: nil, adapterPowerDraw: 0,
        avgTimeToEmptyReg: nil, avgTimeToFullReg: nil,
        updated: Date(timeIntervalSince1970: 0)
    )

    // MARK: - Derived values

    var temperatureF: Double { temperatureC * 9.0 / 5.0 + 32.0 }

    /// Minutes until full. Priority: IOPS estimate → OS smoothed register → computed.
    var bestTimeToFull: Int? {
        if let t = timeToFullMinutes { return t }
        if let t = avgTimeToFullReg { return t }
        guard isCharging, amperage > 0, maxCapacity > currentCapacity else { return nil }
        let mins = Int((Double(maxCapacity - currentCapacity) / Double(amperage) * 60).rounded())
        return mins > 0 ? mins : nil
    }

    /// Minutes until empty. Priority: IOPS estimate → OS smoothed register → computed.
    /// The smoothed register matches what macOS / pmset report, avoiding wild swings from
    /// instantaneous current spikes under load.
    var bestTimeToEmpty: Int? {
        if let t = timeToEmptyMinutes { return t }
        if let t = avgTimeToEmptyReg { return t }
        guard !isACAttached, amperage < 0, currentCapacity > 0 else { return nil }
        let mins = Int((Double(currentCapacity) / Double(-amperage) * 60).rounded())
        return mins > 0 ? mins : nil
    }

    /// Health can exceed 100% on a fresh cell (e.g. 8778/8579 ≈ 102%).
    var healthPercent: Int {
        guard designCapacity > 0 else { return 0 }
        return Int((Double(maxCapacity) / Double(designCapacity) * 100.0).rounded())
    }

    var healthStatus: String {
        switch healthPercent {
        case 80...:  return "Good"
        case 60..<80: return "Fair"
        default:      return "Service"
        }
    }

    var temperatureStatus: String {
        switch temperatureC {
        case ..<35:   return "Normal"
        case 35..<40: return "Warm"
        default:      return "Hot"
        }
    }

    var temperatureIsNormal: Bool { temperatureC < 35 }

    /// Battery-side power magnitude in watts: |V * I|.
    var batteryWatts: Double { abs(voltage * Double(amperage) / 1000.0) }

    /// Power flowing INTO the battery while charging (0 otherwise).
    var chargeWatts: Double { isCharging ? batteryWatts : 0 }

    /// Actual live power being drawn from the adapter (falls back to the rating).
    var adapterInputWatts: Double {
        adapterPowerDraw > 0.5 ? adapterPowerDraw : Double(adapterWatts)
    }

    /// Power consumed by the laptop/system itself.
    /// On AC: actual adapter draw minus what's going into the battery.
    /// On battery: the discharge draw.
    var systemLoadWatts: Double {
        if isACAttached {
            let draw = adapterPowerDraw > 0.5 ? adapterPowerDraw : 0
            return max(0, draw - chargeWatts)
        }
        return batteryWatts
    }

    /// Power Usage shown in the card — actual live consumption, never the adapter's rating.
    /// On AC: real adapter draw (BatteryData.AdapterPower); on battery: discharge draw.
    var powerUsageWatts: Double {
        if isACAttached {
            return adapterPowerDraw > 0.5 ? adapterPowerDraw : batteryWatts
        }
        return batteryWatts
    }

    /// The center "flowing" watts of the Power Flow diagram.
    var flowWatts: Double {
        isACAttached ? max(powerUsageWatts, 0) : batteryWatts
    }

    var currentLabel: String {
        if amperage == 0 { return "Not Charging" }
        return amperage > 0 ? "Charging" : "Discharging"
    }

    /// Short usage hint shown under the power flow (based on the system's own draw).
    var usageHint: String {
        if isCharging {
            switch systemLoadWatts {
            case ..<8:    return "Light use: typical for web and docs"
            case 8..<25:  return "Active workload: multitasking or media"
            default:      return "Very heavy use: peak performance"
            }
        }
        switch systemLoadWatts {
        case ..<8:    return "Light use: typical for web and docs"
        case 8..<20:  return "Moderate use: apps and multitasking"
        case 20..<40: return "Heavy use: demanding workloads"
        default:      return "Very heavy use: peak performance"
        }
    }
}
