import SwiftUI

/// One continuous card holding the collapsible header and every detail section,
/// separated by hairline dividers — matches the real app's dense layout.
struct BatteryInformationCard: View {
    let snap: BatterySnapshot
    @Binding var expanded: Bool
    var onRefresh: () -> Void

    @State private var now = Date()
    private let ticker = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                header

                if expanded {
                    SectionDivider()
                    BatteryHealthSection(snap: snap)
                    SectionDivider()
                    TemperatureSection(snap: snap)
                    SectionDivider()
                    PowerElectricalSection(snap: snap)
                    SectionDivider()
                    CapacityDetailsSection(snap: snap)

                    refreshFooter
                }
            }
        }
        .onReceive(ticker) { now = $0 }
    }

    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Theme.blue)
                Text("Battery Information")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .rotationEffect(.degrees(expanded ? 0 : 180))
            }
        }
        .buttonStyle(.plain)
    }

    private var refreshFooter: some View {
        VStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "info.circle").font(.system(size: 11))
                Text("We refresh your battery health stats every 2 min")
                    .font(.system(size: 12))
            }
            .foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                Text("Updated \(relativeUpdated)")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                Text("•").foregroundStyle(Theme.textTertiary)
                Button(action: onRefresh) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Tap to refresh now")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.blue)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    private var relativeUpdated: String {
        let secs = Int(now.timeIntervalSince(snap.updated))
        if secs < 5 { return "just now" }
        if secs < 60 { return "\(secs)s ago" }
        let mins = secs / 60
        return mins == 1 ? "1 min ago" : "\(mins) min ago"
    }
}
