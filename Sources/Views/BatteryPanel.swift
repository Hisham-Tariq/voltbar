import SwiftUI

/// Root panel — scrollable, assembles every card. Matches the mockup ordering.
struct BatteryPanel: View {
    @ObservedObject var monitor: BatteryMonitor
    @State private var infoExpanded = true
    @State private var visible = false
    @State private var contentHeight: CGFloat = 420

    private var snap: BatterySnapshot { monitor.snapshot }

    /// Cap so the panel never exceeds the usable screen; scrolls if content is taller.
    private var maxPanelHeight: CGFloat {
        (NSScreen.main?.visibleFrame.height ?? 940) - 24
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow)
                .ignoresSafeArea()
            Theme.panelScrim
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: Theme.sectionSpacing) {
                    if snap.hasBattery {
                        HeaderCard(snap: snap)

                        BatteryInformationCard(snap: snap, expanded: $infoExpanded) {
                            monitor.refreshNow()
                        }

                        PanelFooter()
                    } else {
                        NoBatteryView()
                    }
                }
                .padding(14)
                .background(GeometryReader { g in
                    Color.clear.preference(key: ContentHeightKey.self, value: g.size.height)
                })
            }
        }
        .frame(width: Theme.panelWidth)
        .frame(height: min(contentHeight, maxPanelHeight))   // dynamic: fits content, capped
        .onPreferenceChange(ContentHeightKey.self) { h in
            withAnimation(.easeInOut(duration: 0.22)) { contentHeight = h }
        }
        .environment(\.panelVisible, visible)
        .onAppear {
            visible = true
            monitor.panelDidOpen()
        }
        .onDisappear {
            visible = false
            monitor.panelDidClose()
        }
    }

}

/// Reports the panel's natural content height so the window can size to it dynamically.
private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct NoBatteryView: View {
    var body: some View {
        Card {
            VStack(spacing: 10) {
                Image(systemName: "powerplug")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.textSecondary)
                Text("No Battery")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("This Mac has no internal battery.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
}
