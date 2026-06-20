import SwiftUI

@main
struct BubblePreviewApp: App {
    var body: some Scene {
        WindowGroup("Bubble Preview") {
            Color.clear.frame(width: 200, height: 80)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    func fire() {
                        NotificationBubble.show(.init(icon: "battery.25", tint: .orange,
                                                      title: "15% Remaining", subtitle: "9min until empty"))
                    }
                    fire()
                    // Keep re-showing so it's reliably on screen for inspection.
                    Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in fire() }
                }
        }
        .windowResizability(.contentSize)
    }
}
