#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

VERSION="$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)"
APP="build/Sathi.app"
STAGE="build/dmg"
DMG="build/Sathi-$VERSION.dmg"

./build.sh

if [[ -n "$SIGN_IDENTITY" ]]; then
  echo "Signing with ${SIGN_IDENTITY}…"
  codesign --force --deep --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
fi

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

echo "Creating ${DMG}…"
hdiutil create -volname "Sathi $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

if [[ -n "$SIGN_IDENTITY" ]]; then
  codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG"
fi

if [[ -n "$SIGN_IDENTITY" && -n "$NOTARY_PROFILE" ]]; then
  echo "Notarizing (this takes a few minutes)…"
  xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG"
fi

hdiutil verify "$DMG" >/dev/null
cp "$DMG" build/Sathi.dmg
echo "Done: $DMG ($(du -h "$DMG" | cut -f1)), copied to build/Sathi.dmg"
if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "Ad-hoc signed. On another Mac: right-click Sathi.app, then Open."
fi
