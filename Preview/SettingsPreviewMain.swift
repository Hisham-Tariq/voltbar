import SwiftUI

@main
struct SettingsPreviewApp: App {
    var body: some Scene {
        WindowGroup("Settings Preview") {
            SettingsRoot()
                .onAppear { NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps: true) }
        }
        .windowResizability(.contentSize)
    }
}
