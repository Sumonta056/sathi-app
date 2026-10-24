#!/bin/bash
# Builds Sathi.app from source. Usage:
#   ./build.sh            -> builds build/Sathi.app
#   ./build.sh --install  -> builds, copies to /Applications and opens it
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v swift >/dev/null 2>&1; then
  echo "Swift is not installed. Run:  xcode-select --install   then try again."
  exit 1
fi

echo "Building Sathi (release)…"
swift build -c release

BIN="$(swift build -c release --show-bin-path)/Sathi"
APP="build/Sathi.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Sathi"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc sign so macOS lets it run and "Open at login" works.
codesign --force --deep --sign - "$APP"

echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  pkill -x Sathi 2>/dev/null || true
  rm -rf /Applications/Sathi.app
  cp -R "$APP" /Applications/
  echo "Installed to /Applications/Sathi.app"
  open /Applications/Sathi.app
fi
