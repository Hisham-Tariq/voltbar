import Foundation
import IOKit
import IOKit.ps
import AppKit
import Combine

/// Single shared monitor for the app lifetime.
///
/// Power strategy:
///  - A Core Foundation run-loop source (IOPSNotificationCreateRunLoopSource) wakes us ONLY
///    when the power state changes (plug/unplug, charge %, charging flag). That keeps the
///    menu-bar icon current at near-zero idle cost — no timer.
///  - Detailed AppleSmartBattery reads (temp/voltage/watts/capacity) only run while the panel
///    is open, on a coalesced DispatchSourceTimer with large leeway. Closing the panel
///    invalidates the timer immediately.
///  - Sleep pauses everything; wake resumes and does one fresh read.
final class BatteryMonitor: ObservableObject {

    /// Single shared instance for the whole app (UI + alert engine).
    static let shared = BatteryMonitor()

    @Published private(set) var snapshot: BatterySnapshot = .placeholder

    private var psRunLoopSource: CFRunLoopSource?
    private var liveTimer: DispatchSourceTimer?
    private var panelOpen = false
    private var asleep = false

    /// Cadence for the slow refresh while the panel is open (seconds).
    private let liveInterval: Int = 30
    private let liveLeeway: DispatchTimeInterval = .seconds(10)

    init() {
        registerPowerSourceNotification()
        registerSleepWake()
        refreshNow()   // one read at launch so the icon is correct immediately
    }

    deinit {
        if let src = psRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), src, .commonModes)
        }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        liveTimer?.cancel()
    }

    // MARK: - Panel visibility gating

    func panelDidOpen() {
        panelOpen = true
        refreshNow()
        startLiveTimer()
    }

    func panelDidClose() {
        panelOpen = false
        stopLiveTimer()
    }

    /// Single immediate full read (used at launch, on panel open, and "Tap to refresh now").
    func refreshNow() {
        let snap = Self.readSnapshot()
        // Publish on main; coalesce identical reads to avoid needless view churn.
        if snap != snapshot {
            snapshot = snap
        } else {
            // Even when nothing changed, advance the timestamp on an explicit refresh.
            snapshot.updated = snap.updated
        }
    }

    // MARK: - Power-source notification (lightweight, event driven)

    private func registerPowerSourceNotification() {
        let ctx = Unmanaged.passUnretained(self).toOpaque()
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.handlePowerSourceChange()
        }
        guard let src = IOPSNotificationCreateRunLoopSource(callback, ctx)?.takeRetainedValue() else {
            return
        }
        psRunLoopSource = src
        CFRunLoopAddSource(CFRunLoopGetMain(), src, .commonModes)
    }

    private func handlePowerSourceChange() {
        guard !asleep else { return }
        // A state change is exactly when the icon must update. Detailed fields are cheap
        // enough to read here too, but they only matter if the panel is open.
        refreshNow()
    }

    // MARK: - Sleep / wake

    private func registerSleepWake() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(willSleep),
                       name: NSWorkspace.willSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(didWake),
                       name: NSWorkspace.didWakeNotification, object: nil)
    }

    @objc private func willSleep() {
        asleep = true
        stopLiveTimer()
    }

    @objc private func didWake() {
        asleep = false
        refreshNow()
        if panelOpen { startLiveTimer() }
    }

    // MARK: - Coalesced live timer (only while panel open)

    private func startLiveTimer() {
        stopLiveTimer()
        guard panelOpen, !asleep else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + .seconds(liveInterval),
                       repeating: .seconds(liveInterval),
                       leeway: liveLeeway)
        timer.setEventHandler { [weak self] in self?.refreshNow() }
        timer.resume()
        liveTimer = timer
    }

    private func stopLiveTimer() {
        liveTimer?.cancel()
        liveTimer = nil
    }

    // MARK: - IOKit reads

    /// Reads both IOPowerSources (light) and AppleSmartBattery (detailed) into one snapshot.
    static func readSnapshot() -> BatterySnapshot {
        var snap = BatterySnapshot.placeholder
        snap.updated = Date()
        readPowerSources(into: &snap)
        readSmartBattery(into: &snap)
        return snap
    }

    private static func readPowerSources(into snap: inout BatterySnapshot) {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef]
        else { return }

        for ps in list {
            guard let desc = IOPSGetPowerSourceDescription(blob, ps)?
                .takeUnretainedValue() as? [String: Any] else { continue }

            if let type = desc[kIOPSTypeKey] as? String,
               type != kIOPSInternalBatteryType { continue }

            snap.hasBattery = true

            if let cur = desc[kIOPSCurrentCapacityKey] as? Int,
               let mx = desc[kIOPSMaxCapacityKey] as? Int, mx > 0 {
                snap.percent = Int((Double(cur) / Double(mx) * 100.0).rounded())
            }
            if let charging = desc[kIOPSIsChargingKey] as? Bool {
                snap.isCharging = charging
            }
            if let state = desc[kIOPSPowerSourceStateKey] as? String {
                snap.isACAttached = (state == kIOPSACPowerValue)
            }
            if let charged = desc[kIOPSIsChargedKey] as? Bool {
                snap.isFullyCharged = charged
            }
            if let ttf = desc[kIOPSTimeToFullChargeKey] as? Int, ttf >= 0 {
                snap.timeToFullMinutes = ttf
            }
            if let tte = desc[kIOPSTimeToEmptyKey] as? Int, tte >= 0 {
                snap.timeToEmptyMinutes = tte
            }
        }
    }

    private static func readSmartBattery(into snap: inout BatterySnapshot) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault,
                                                  IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return }
        defer { IOObjectRelease(service) }

        var unmanaged: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let props = unmanaged?.takeRetainedValue() as? [String: Any]
        else { return }

        snap.hasBattery = (props["BatteryInstalled"] as? Bool) ?? snap.hasBattery

        if let v = props["CycleCount"] as? Int { snap.cycleCount = v }
        if let v = props["DesignCapacity"] as? Int { snap.designCapacity = v }
        if let v = props["AppleRawMaxCapacity"] as? Int { snap.maxCapacity = v }
        if let v = props["AppleRawCurrentCapacity"] as? Int { snap.currentCapacity = v }
        if let v = props["Temperature"] as? Int { snap.temperatureC = Double(v) / 100.0 }
        if let v = props["Voltage"] as? Int { snap.voltage = Double(v) / 1000.0 }

        // Prefer instantaneous current when present and non-zero.
        let inst = props["InstantAmperage"] as? Int ?? 0
        let amp = props["Amperage"] as? Int ?? 0
        snap.amperage = inst != 0 ? inst : amp

        if let charging = props["IsCharging"] as? Bool { snap.isCharging = charging }
        if let charged = props["FullyCharged"] as? Bool { snap.isFullyCharged = charged }

        if let adapter = props["AdapterDetails"] as? [String: Any] {
            if let w = adapter["Watts"] as? Int { snap.adapterWatts = w }
            if let name = adapter["Name"] as? String { snap.adapterName = name }
        }

        // Live adapter power (watts) is reported inside BatteryData on Apple Silicon.
        if let bd = props["BatteryData"] as? [String: Any],
           let ap = bd["AdapterPower"] as? Double {
            snap.adapterPowerDraw = ap
        }

        // OS smoothed time estimates (minutes); 65535/0 = invalid/calculating.
        if let v = props["AvgTimeToEmpty"] as? Int, v > 0, v < 65535 { snap.avgTimeToEmptyReg = v }
        if let v = props["AvgTimeToFull"] as? Int, v > 0, v < 65535 { snap.avgTimeToFullReg = v }
    }
}
