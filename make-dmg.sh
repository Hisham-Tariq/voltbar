#!/bin/bash
# Builds Voltbar.app and packages a drag-to-Applications disk image (Voltbar.dmg).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/Voltbar.app"
STAGE="$ROOT/build/dmg"
DMG="$ROOT/build/Voltbar.dmg"
VOLNAME="Voltbar"

# 1. Fresh app build
"$ROOT/build.sh"

# 2. Staging folder: the app + an Applications shortcut
rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# 3. Build a read-write image so we can set the window layout
TMP_DMG="$ROOT/build/Voltbar-rw.dmg"
rm -f "$TMP_DMG"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -fs HFS+ \
  -format UDRW -ov "$TMP_DMG" >/dev/null

# 4. Mount, arrange icons, set window, unmount
MOUNT_DIR="/Volumes/$VOLNAME"
hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
hdiutil attach "$TMP_DMG" -noautoopen -mountpoint "$MOUNT_DIR" >/dev/null

osascript <<EOF || true
tell application "Finder"
  tell disk "$VOLNAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {200, 120, 720, 480}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 112
    set position of item "Voltbar.app" of container window to {130, 170}
    set position of item "Applications" of container window to {390, 170}
    update without registering applications
    delay 1
    close
  end tell
end tell
EOF
sync

# 5. Convert to compressed read-only final image
hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
hdiutil convert "$TMP_DMG" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG" >/dev/null
rm -f "$TMP_DMG"
rm -rf "$STAGE"

echo "==> Created $DMG"
ls -lh "$DMG"
