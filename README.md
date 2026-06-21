<div align="center">

# ⚡ Voltbar

**A native, power-efficient battery panel for the macOS menu bar.**

Live battery health, temperature, voltage, current, real-time power flow, and
Dynamic-Island-style alerts — built in pure Swift + SwiftUI + IOKit. No Electron,
no telemetry, no network, idles at ~0% CPU.

[Download](https://github.com/Hisham-Tariq/voltbar/releases/latest) ·
[Website](https://hisham-tariq.github.io/voltbar/) ·
[Report a bug](https://github.com/Hisham-Tariq/voltbar/issues)

</div>

---

## Features

- **Menu-bar icon** with the live percentage inside — outline on battery, filled green + bolt while charging, orange/red when low.
- **Glass panel** that drops down on click: big % readout, time-to-full / time-to-empty, and a segmented charge bar.
- **Battery Health** — capacity vs. design (can exceed 100%), cycle count.
- **Temperature** — °C / °F with a normal/warm/hot status.
- **Power & Electrical** — live power usage (W), voltage (V), current (mA), charge state.
- **Power Flow** — a dynamic curved split showing power into the battery vs. the laptop while charging.
- **Capacity Details** — remaining / current-full / design (mAh).
- **Alerts** — low-battery thresholds, charged target, and plug/unplug notifications shown as a glowing Dynamic-Island-style bubble, each with its own preview.
- **Settings** — a macOS System Settings-style window (General / Alerts / About), Launch at Login, and a deep link to the system Battery pane.

## Why it's light on power

Minimal power use is the #1 design constraint:

- **Event-driven**, not polling — the menu-bar icon updates only when the power source changes (`IOPSNotificationCreateRunLoopSource`).
- **Detailed reads are gated by visibility** — temperature/voltage/watts only refresh while the panel is open, on a coalesced timer (30s, 10s leeway). Closing the panel stops it immediately.
- **Sleep/wake aware** — timers pause on sleep, resume on wake.
- **No animations while hidden. Zero network. No Bluetooth.**

Observed: **~0.0% idle CPU** with the panel closed.

## Install

### Download (easiest)
1. Download **[Voltbar.dmg](https://github.com/Hisham-Tariq/voltbar/releases/latest/download/Voltbar.dmg)** from the latest release and open it.
2. Drag **Voltbar** onto the **Applications** shortcut in the window.
3. First launch: right-click Voltbar → **Open** (the build is ad-hoc signed, not notarized).
   If macOS still blocks it, run once:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Voltbar.app
   ```

> A `Voltbar.zip` is also attached to each release if you prefer that.

### Build from source
Requires the Swift toolchain (Xcode or Command Line Tools) on Apple Silicon, macOS 14+.
```bash
git clone https://github.com/Hisham-Tariq/voltbar.git
cd voltbar
./build.sh            # compiles build/Voltbar.app and ad-hoc signs it
open build/Voltbar.app
```

## Architecture

```
Sources/
  VoltbarApp.swift            @main, MenuBarExtra (.window style), LSUIElement
  Model/BatterySnapshot.swift immutable value type — one read → all fields
  Services/
    BatteryMonitor.swift      shared ObservableObject; IOKit + power-source notifications
    AlertSettings.swift       persisted alert preferences (UserDefaults)
    AlertEngine.swift         event-driven threshold/plug detection
  Views/
    BatteryPanel.swift        root panel, dynamic height
    HeaderCard / BatteryInformationCard / DetailCards / PowerFlowView
    MenuBarIcon.swift         rendered battery glyph + %
    NotificationBubble.swift  Dynamic-Island alert panel
    SettingsView.swift        sidebar settings window
  Theme/Theme.swift           color / radius / spacing tokens
```

## Compatibility

- **macOS 14 (Sonoma)+**, Apple Silicon. Reads `AppleSmartBattery` via IOKit, so it's for Macs with a battery (laptops). Desktops show a "No Battery" state.

## License

[MIT](LICENSE) © Hisham Tariq

> Voltbar is an independent open-source project and is not affiliated with any other battery utility.
