import SwiftUI
import ServiceManagement

/// Opens / focuses the Settings window from the menu-bar agent. Managed via AppKit so it
/// only ever appears on demand (a SwiftUI `Window` scene would auto-open at launch).
/// Switches to a regular, Dock-visible policy while open and back to accessory on close.
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show() {
        NSApp.setActivationPolicy(.regular)
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsRoot())
            let w = NSWindow(contentViewController: hosting)
            w.title = "Voltbar Settings"
            w.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            w.titlebarAppearsTransparent = false
            w.setContentSize(NSSize(width: 720, height: 460))
            w.isReleasedWhenClosed = false
            w.center()
            w.delegate = self
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        // Return to menu-bar-only once the settings window closes.
        NSApp.setActivationPolicy(.accessory)
    }
}

/// Root settings view with a macOS System Settings-style sidebar.
struct SettingsRoot: View {
    enum Pane: String, CaseIterable, Identifiable {
        case general, alerts, about
        var id: String { rawValue }
        var title: String {
            switch self { case .general: return "General"; case .alerts: return "Alerts"; case .about: return "About" }
        }
        var icon: String {
            switch self { case .general: return "gearshape.fill"; case .alerts: return "bell.fill"; case .about: return "info" }
        }
        var tint: Color {
            switch self {
            case .general: return Theme.green
            case .alerts:  return Color(hex: 0x34C759)
            case .about:   return Color(hex: 0x7C6CF5)
            }
        }
    }

    @State private var selection: Pane = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(Pane.allCases) { pane in
                    SidebarRow(title: pane.title, icon: pane.icon, tint: pane.tint)
                        .tag(pane)
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 215, max: 240)
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selection {
                case .general: GeneralSettings()
                case .alerts:  AlertsSettings()
                case .about:   AboutSettings()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle(selection.title)
        .frame(width: 720, height: 460)
    }
}

/// macOS-Settings-style sidebar row: rounded colored icon tile + label.
struct SidebarRow: View {
    var title: String
    var icon: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(tint)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 22, height: 22)
            Text(title).font(.system(size: 13))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - General pane

struct GeneralSettings: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsHeader(icon: "gearshape.fill", tint: Theme.green, title: "General",
                               subtitle: "Basic app settings and preferences")

                SettingsGroup(title: "System Integration", glyph: "power", glyphTint: Theme.green) {
                    SettingsToggleRow(
                        icon: "power", iconTint: Theme.green,
                        title: "Launch at Login",
                        subtitle: "Start Voltbar automatically when you log in",
                        isOn: $launchAtLogin
                    )
                    .onChange(of: launchAtLogin) { _, on in setLogin(on) }
                }

                SettingsGroup(title: "Refresh", glyph: "arrow.clockwise", glyphTint: Theme.blue) {
                    HStack {
                        Image(systemName: "clock.fill").foregroundStyle(Theme.blue).frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Live Refresh").font(.system(size: 13, weight: .medium))
                            Text("Detailed stats update every 30s while the panel is open")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                }
            }
            .padding(28)
        }
    }

    private func setLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

// MARK: - About pane

struct AboutSettings: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsHeader(icon: "info", tint: Color(hex: 0x7C6CF5), title: "About",
                               subtitle: "About this app")

                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(colors: [Theme.green, Theme.greenDim],
                                                 startPoint: .top, endPoint: .bottom))
                        Image(systemName: "bolt.fill").font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 80, height: 80)
                    Text("Voltbar").font(.system(size: 20, weight: .bold))
                    Text("Version \(version)").font(.system(size: 13)).foregroundStyle(.secondary)
                    Text("A native, power-efficient battery panel for macOS.\nBuilt with Swift, SwiftUI & IOKit.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            }
            .padding(28)
        }
    }
}

// MARK: - Alerts pane

struct AlertsSettings: View {
    @ObservedObject private var s = AlertSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SettingsHeader(icon: "bell.fill", tint: Color(hex: 0x34C759), title: "Alerts",
                               subtitle: "Configure battery notifications and visual effects")

                SettingsGroup(title: "General", glyph: "gearshape", glyphTint: .secondary) {
                    SettingsToggleRow(icon: "bell.fill", iconTint: Theme.blue,
                                      title: "Enable Notifications",
                                      subtitle: "Show battery alerts and notifications",
                                      isOn: $s.enabled)
                }

                // Low battery thresholds
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "battery.25").foregroundStyle(Theme.red)
                        Text("Low Battery Alerts").font(.system(size: 16, weight: .semibold))
                    }
                    Text("Notify when battery goes below percentage")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    ForEach(s.lowThresholds, id: \.self) { t in
                        AlertChipRow(percent: t, tint: chipColor(t),
                                     subtitle: t <= 10 ? "Center of Screen" : "Top of Screen",
                                     onPreview: {
                                        NotificationBubble.show(.init(
                                            icon: "battery.25", tint: t <= 10 ? .red : .orange,
                                            title: "\(t)% Remaining", subtitle: "9min until empty"))
                                     },
                                     onDelete: { s.removeLowThreshold(t) })
                    }
                    Button { s.addLowThreshold() } label: {
                        Label("Add Low Battery Alert", systemImage: "plus")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }

                // Charged
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "battery.100.bolt").foregroundStyle(Theme.green)
                        Text("Charged Alerts").font(.system(size: 16, weight: .semibold))
                    }
                    Text("Notify when battery reaches percentage")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                    HStack {
                        AlertChip(percent: s.chargedThreshold, tint: Theme.green, charging: true)
                        Stepper("", value: $s.chargedThreshold, in: 50...100, step: 5).labelsHidden()
                        Spacer()
                        PreviewButton {
                            NotificationBubble.show(.init(
                                icon: "battery.100.bolt", tint: .green,
                                title: "Charged to \(s.chargedThreshold)%", subtitle: "Target reached"))
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "powerplug.fill").foregroundStyle(Theme.orange)
                        Text("Power Source Alerts").font(.system(size: 16, weight: .semibold))
                    }
                    VStack(spacing: 0) {
                        TogglePreviewRow(icon: "bolt.fill", iconTint: Theme.orange,
                                         title: "Plugged In", subtitle: "Notify when power adapter is connected",
                                         isOn: $s.notifyPluggedIn,
                                         onPreview: {
                                            NotificationBubble.show(.init(icon: "powerplug.fill", tint: .green,
                                                title: "Power Connected", subtitle: "79% • charging")) })
                        Divider().padding(.leading, 46)
                        TogglePreviewRow(icon: "powerplug", iconTint: Theme.orange,
                                         title: "Unplugged", subtitle: "Notify when power adapter is disconnected",
                                         isOn: $s.notifyUnplugged,
                                         onPreview: {
                                            NotificationBubble.show(.init(icon: "powerplug", tint: .orange,
                                                title: "Running on Battery", subtitle: "79% remaining")) })
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
                }
            }
            .padding(28)
        }
    }

    private func chipColor(_ t: Int) -> Color {
        switch t { case ..<15: return Theme.red; case 15..<25: return Theme.orange; default: return Color(hex: 0xEAB308) }
    }
}

struct AlertChip: View {
    var percent: Int; var tint: Color; var charging: Bool = false
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: charging ? "battery.100.bolt" : "battery.25").foregroundStyle(tint)
            Text("\(percent)%")
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 6).fill(tint.opacity(0.22)))
        }
    }
}

struct AlertChipRow: View {
    var percent: Int; var tint: Color; var subtitle: String
    var onPreview: () -> Void; var onDelete: () -> Void
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                AlertChip(percent: percent, tint: tint)
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            PreviewButton(action: onPreview)
            Button(action: onDelete) {
                Image(systemName: "trash").foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
    }
}

/// Small "preview" pill button used on each alert to show how its notification looks.
struct PreviewButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("Preview", systemImage: "play.fill")
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 9).padding(.vertical, 5)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

/// A toggle row with its own preview button (for Plugged In / Unplugged).
struct TogglePreviewRow: View {
    var icon: String; var iconTint: Color; var title: String; var subtitle: String
    @Binding var isOn: Bool
    var onPreview: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconTint).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            PreviewButton(action: onPreview)
            Toggle("", isOn: $isOn).toggleStyle(.switch).labelsHidden().controlSize(.small)
        }
        .padding(12)
    }
}

// MARK: - Reusable settings building blocks

struct SettingsHeader: View {
    var icon: String; var tint: Color; var title: String; var subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tint)
                    Image(systemName: icon).font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
                Text(title).font(.system(size: 26, weight: .bold))
            }
            Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary)
        }
    }
}

struct SettingsGroup<Content: View>: View {
    var title: String; var glyph: String; var glyphTint: Color
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: glyph).font(.system(size: 14, weight: .semibold)).foregroundStyle(glyphTint)
                Text(title).font(.system(size: 16, weight: .semibold))
            }
            VStack(spacing: 0) { content }
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.05)))
        }
    }
}

struct SettingsToggleRow: View {
    var icon: String; var iconTint: Color; var title: String; var subtitle: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconTint).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn).toggleStyle(.switch).labelsHidden().controlSize(.small)
        }
        .padding(12)
    }
}
