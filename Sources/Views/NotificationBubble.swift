import SwiftUI
import AppKit

/// Content for one notification bubble.
struct BubbleContent: Identifiable {
    let id = UUID()
    var icon: String
    var tint: Color
    var title: String
    var subtitle: String
}

/// Shows a floating Dynamic-Island-style notification near the top of the screen.
/// Uses a borderless non-activating panel so it never steals focus or shows in the Dock.
enum NotificationBubble {
    private static var controller: BubblePanelController?

    static func show(_ content: BubbleContent) {
        DispatchQueue.main.async {
            if controller == nil { controller = BubblePanelController() }
            controller?.present(content)
        }
    }
}

final class BubblePanelController {
    private let panel: NSPanel
    private let hosting: NSHostingView<BubbleHostView>
    private var dismissWork: DispatchWorkItem?
    private let model = BubbleModel()

    init() {
        hosting = NSHostingView(rootView: BubbleHostView(model: model))
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 480, height: 150),
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: true)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false      // keep visible even when our app isn't frontmost
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.ignoresMouseEvents = false
        panel.contentView = hosting
        model.onClose = { [weak self] in self?.dismiss() }
    }

    func present(_ content: BubbleContent) {
        model.content = content
        model.visible = false
        position()
        panel.orderFrontRegardless()
        // Trigger the slide-in on the next runloop so the animation always plays.
        DispatchQueue.main.async { [weak self] in self?.model.visible = true }

        dismissWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.dismiss() }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: work)
    }

    private func dismiss() {
        model.visible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.panel.orderOut(nil)
        }
    }

    private func position() {
        guard let screen = NSScreen.main else { return }
        let size = NSSize(width: 480, height: 150)
        panel.setContentSize(size)
        let vf = screen.visibleFrame
        let x = vf.midX - size.width / 2
        let y = vf.maxY - size.height - 8   // just below the menu bar
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

/// Observable wrapper so the SwiftUI view animates in/out.
final class BubbleModel: ObservableObject {
    @Published var content: BubbleContent = .init(icon: "battery.50", tint: .green,
                                                  title: "", subtitle: "")
    @Published var visible = false
    var onClose: () -> Void = {}
}

struct BubbleHostView: View {
    @ObservedObject var model: BubbleModel

    var body: some View {
        VStack {
            BubbleView(content: model.content, visible: model.visible, onClose: model.onClose)
                .offset(y: model.visible ? 0 : -140)
                .opacity(model.visible ? 1 : 0)
                .animation(.spring(response: 0.42, dampingFraction: 0.82), value: model.visible)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 10)
    }
}

/// The pill — dark capsule with a bright animated glowing arc sweeping the border,
/// a large colored battery tile, big title/subtitle, and a hover-only close button.
struct BubbleView: View {
    let content: BubbleContent
    var visible: Bool
    var onClose: () -> Void
    @State private var hover = false
    @State private var sweep: CGFloat = 0

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(content.tint.opacity(0.20))
                Image(systemName: content.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(content.tint)
            }
            .frame(width: 56, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(content.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(content.subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            if hover {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white.opacity(0.14)))
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .frame(width: 420)
        .background(
            ZStack {
                Capsule(style: .continuous).fill(Color(white: 0.11))
                // Dim full base ring underneath.
                Capsule(style: .continuous)
                    .strokeBorder(content.tint.opacity(0.16), lineWidth: 3.5)
                // Bright glowing ring that draws around the whole capsule on appear.
                Capsule(style: .continuous)
                    .trim(from: 0, to: sweep)
                    .stroke(content.tint,
                            style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                    .shadow(color: content.tint.opacity(0.95), radius: 5)
                    .shadow(color: content.tint.opacity(0.75), radius: 12)
                    .shadow(color: content.tint.opacity(0.5), radius: 20)
            }
            .shadow(color: .black.opacity(0.45), radius: 20, y: 8)
        )
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hover = h } }
        .onChange(of: visible) { _, v in animateSweep(v) }
        .onAppear { animateSweep(visible) }
    }

    private func animateSweep(_ v: Bool) {
        if v {
            sweep = 0
            withAnimation(.easeInOut(duration: 0.9)) { sweep = 1.0 }   // draw full ring around
        } else {
            sweep = 0
        }
    }
}
