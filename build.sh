#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/Voltbar.app"
MACOS="$APP/Contents/MacOS"
RES="$APP/Contents/Resources"
TARGET="arm64-apple-macos14.0"

echo "==> Cleaning"
rm -rf "$APP"
mkdir -p "$MACOS" "$RES"

echo "==> Compiling Swift sources"
SOURCES=$(find "$ROOT/Sources" -name '*.swift')
xcrun swiftc \
    -target "$TARGET" \
    -sdk "$(xcrun --sdk macosx --show-sdk-path)" \
    -O \
    -framework SwiftUI -framework AppKit -framework IOKit -framework ServiceManagement \
    -o "$MACOS/Voltbar" \
    $SOURCES

echo "==> Assembling bundle"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP"

echo "==> Done: $APP"
