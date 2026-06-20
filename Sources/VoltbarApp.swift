import SwiftUI

@main
struct VoltbarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // Single shared monitor for the whole app lifetime.
    @StateObject private var monitor = BatteryMonitor.shared

    var body: some Scene {
        MenuBarExtra {
            BatteryPanel(monitor: monitor)
        } label: {
            Image(nsImage: MenuBarIcon.image(for: monitor.snapshot))
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Start the event-driven alert engine on the shared monitor.
        AlertEngine.shared.start(monitor: BatteryMonitor.shared)
    }
}
