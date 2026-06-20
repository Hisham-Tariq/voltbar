import SwiftUI

/// Footer action list: Settings, Battery Settings (opens macOS System Settings), Quit.
/// Styled like the real app's bottom rows.
struct PanelFooter: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            FooterRow(icon: "gearshape.fill", color: Theme.gray, title: "Settings…", showChevron: true) {
                SettingsWindowController.shared.show()
            }
            divider
            FooterRow(icon: "battery.100", color: Theme.green, title: "Battery Settings…", showChevron: true) {
                openMacBatterySettings()
            }
            divider
            FooterRow(icon: "power", color: Theme.red, title: "Quit Voltbar",
                      trailing: appVersion) {
                NSApp.terminate(nil)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(Theme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .strokeBorder(Theme.cardStroke, lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle().fill(Theme.divider).frame(height: 1).padding(.leading, 48)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "v\(v)"
    }

    private func openMacBatterySettings() {
        // System Settings (Ventura+) battery pane, with older fallbacks.
        let candidates = [
            "x-apple.systempreferences:com.apple.Battery-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.battery",
        ]
        for s in candidates {
            if let url = URL(string: s) {
                openURL(url)
                return
            }
        }
    }
}

/// One tappable footer row: colored leading glyph, title, trailing chevron or text.
struct FooterRow: View {
    var icon: String
    var color: Color
    var title: String
    var showChevron: Bool = false
    var trailing: String? = nil
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 22)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
            .background(hovering ? Color.white.opacity(0.05) : Color.clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
