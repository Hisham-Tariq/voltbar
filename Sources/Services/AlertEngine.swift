import Foundation
import Combine

/// Watches battery snapshots (event-driven, no polling of its own) and fires notification
/// bubbles when thresholds are crossed: low battery, charged target, and plug/unplug.
final class AlertEngine {
    static let shared = AlertEngine()

    private let settings = AlertSettings.shared
    private var lastPercent: Int?
    private var lastAC: Bool?
    private var cancellable: AnyCancellable?

    func start(monitor: BatteryMonitor) {
        cancellable = monitor.$snapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snap in self?.handle(snap) }
    }

    private func handle(_ snap: BatterySnapshot) {
        defer { lastPercent = snap.percent; lastAC = snap.isACAttached }
        guard snap.hasBattery, settings.enabled else { return }
        guard let lp = lastPercent else { return }   // need a baseline to detect a crossing

        // Plug / unplug transitions.
        if let la = lastAC, la != snap.isACAttached {
            if snap.isACAttached, settings.notifyPluggedIn {
                NotificationBubble.show(.init(
                    icon: "powerplug.fill", tint: .green,
                    title: "Power Connected", subtitle: "\(snap.percent)% • charging"))
            } else if !snap.isACAttached, settings.notifyUnplugged {
                NotificationBubble.show(.init(
                    icon: "powerplug", tint: .orange,
                    title: "Running on Battery", subtitle: "\(snap.percent)% remaining"))
            }
        }

        // Low-battery crossings (only while discharging).
        if !snap.isACAttached, snap.percent < lp {
            for t in settings.lowThresholds.sorted(by: >) where lp > t && snap.percent <= t {
                let sub = snap.bestTimeToEmpty.map { "\(fmt($0)) until empty" } ?? "Plug in soon"
                NotificationBubble.show(.init(
                    icon: "battery.25", tint: t <= 10 ? .red : .orange,
                    title: "\(snap.percent)% Remaining", subtitle: sub))
            }
        }

        // Charged target reached (while on power).
        if snap.isACAttached, snap.percent > lp {
            let t = settings.chargedThreshold
            if lp < t && snap.percent >= t {
                NotificationBubble.show(.init(
                    icon: "battery.100.bolt", tint: .green,
                    title: "Charged to \(snap.percent)%", subtitle: "Target reached"))
            }
        }
    }

    private func fmt(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)min" }
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}
