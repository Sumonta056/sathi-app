---
name: make-dmg
description: Build a Sathi DMG installer for sharing, optionally with a version bump, Developer ID signing, and notarization. Use when the user types /make-dmg, or asks to "make a dmg", "package the app", "make an installer", "release a version", or "share the app".
---

# /make-dmg: package Sathi as a DMG

Input: `$ARGUMENTS` may hold a version (for example `1.1`). If it is empty, keep the current version.

## 1. Check that the code is ready

1. `git status --short`. If `Sources/` or `Tests/` have uncommitted changes, tell the user and ask whether to continue.
2. Run `./scripts/lint.sh` and `./scripts/test.sh`. Stop if either fails.

## 2. Version (only if the user gave one)

1. Read the current version: `/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist`.
2. Set the new version and raise the build number by 1:
   ```
   /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString <version>" Resources/Info.plist
   /usr/libexec/PlistBuddy -c "Set CFBundleVersion <build + 1>" Resources/Info.plist
   ```

## 3. Build the DMG

Ask the user which kind they need:

| Kind | Command | Who can open it |
|---|---|---|
| Ad-hoc (default) | `./scripts/make-dmg.sh` | You. Others right-click Sathi.app → **Open** the first time. |
| Signed + notarized | `SIGN_IDENTITY="Developer ID Application: <Name> (<TEAMID>)" NOTARY_PROFILE=<profile> ./scripts/make-dmg.sh` | Anyone, with no warning. Needs a paid Apple Developer account. |

To find the identity: `security find-identity -v -p codesigning`. To create the notary profile once: `xcrun notarytool store-credentials <profile>`. Never print or store the Apple ID password in a file.

The script writes `build/Sathi-<version>.dmg`. Copy it to the project root:

```
cp build/Sathi-<version>.dmg ./
```

`*.dmg` is in `.gitignore`, so the DMG is never committed.

## 4. Verify

1. `hdiutil verify Sathi-<version>.dmg` must report `VALID`.
2. Mount it and check that it holds `Sathi.app` and an `Applications` shortcut:
   ```
   M=$(hdiutil attach -nobrowse -readonly Sathi-<version>.dmg | tail -1 | cut -f3); ls "$M"; codesign -dv "$M/Sathi.app" 2>&1 | grep -E "Identifier|Signature|TeamIdentifier"; hdiutil detach -quiet "$M"
   ```
3. For a notarized DMG: `spctl -a -t open --context context:primary-signature -v Sathi-<version>.dmg` must say `accepted`.

## 5. Report and finish

1. Report: the path, the size, the version, the signature kind, and the verify result.
2. If you changed the version, ask before committing `Resources/Info.plist`. Offer a git tag `v<version>`. Never push without approval.

## App icon

- Source of truth: `Resources/AppIcon.icns`. A 1024 × 1024 preview is in `Resources/AppIcon.png`.
- To change the icon, put a new 1024 × 1024 PNG at `Resources/AppIcon.png`, then rebuild the `.icns`:
  ```
  I=build/AppIcon.iconset; mkdir -p $I
  for s in 16 32 128 256 512; do
    sips -z $s $s Resources/AppIcon.png --out $I/icon_${s}x${s}.png >/dev/null
    sips -z $((s*2)) $((s*2)) Resources/AppIcon.png --out $I/icon_${s}x${s}@2x.png >/dev/null
  done
  iconutil -c icns $I -o Resources/AppIcon.icns
  ```
