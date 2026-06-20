import SwiftUI

// Verification-only harness: hosts the real BatteryPanel in a normal window so it
// can be screenshotted. Not part of the shipping menu-bar app.
@main
struct PreviewApp: App {
    @StateObject private var monitor = BatteryMonitor()
    var body: some Scene {
        WindowGroup("Battery Panel Preview") {
            // No forced frame — uses BatteryPanel's own intrinsic size so the preview
            // reflects the real menu-bar panel's dimensions and text proportions.
            BatteryPanel(monitor: monitor)
                .onAppear { NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps: true) }
        }
        .windowResizability(.contentSize)
    }
}
