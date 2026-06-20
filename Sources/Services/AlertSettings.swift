import Foundation
import Combine

/// User-configurable alert preferences, persisted in UserDefaults.
final class AlertSettings: ObservableObject {
    static let shared = AlertSettings()

    @Published var enabled: Bool { didSet { d.set(enabled, forKey: "alerts.enabled") } }
    @Published var lowThresholds: [Int] { didSet { d.set(lowThresholds, forKey: "alerts.low") } }
    @Published var chargedThreshold: Int { didSet { d.set(chargedThreshold, forKey: "alerts.charged") } }
    @Published var notifyPluggedIn: Bool { didSet { d.set(notifyPluggedIn, forKey: "alerts.plugged") } }
    @Published var notifyUnplugged: Bool { didSet { d.set(notifyUnplugged, forKey: "alerts.unplugged") } }

    private let d = UserDefaults.standard

    private init() {
        enabled = d.object(forKey: "alerts.enabled") as? Bool ?? true
        lowThresholds = (d.array(forKey: "alerts.low") as? [Int]) ?? [30, 20, 10]
        chargedThreshold = d.object(forKey: "alerts.charged") as? Int ?? 80
        notifyPluggedIn = d.object(forKey: "alerts.plugged") as? Bool ?? true
        notifyUnplugged = d.object(forKey: "alerts.unplugged") as? Bool ?? true
    }

    func addLowThreshold() {
        let candidates = [50, 40, 30, 25, 20, 15, 10, 5]
        if let next = candidates.first(where: { !lowThresholds.contains($0) }) {
            lowThresholds = (lowThresholds + [next]).sorted(by: >)
        }
    }

    func removeLowThreshold(_ t: Int) {
        lowThresholds.removeAll { $0 == t }
    }
}
