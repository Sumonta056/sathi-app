---
name: sathi-release
description: Release Sathi to GitHub with a DMG, and keep the website and README current. Use when the user asks to release, publish, cut a version, tag, ship a DMG, or "make a release".
---

# Sathi release

A release has 5 parts that must agree:

1. `CFBundleShortVersionString` in `Resources/Info.plist`
2. a `## [X.Y.Z]` section in `CHANGELOG.md`
3. the JSON-LD `softwareVersion` and the version text in `site/index.html`
4. tag `vX.Y.Z` on `main`
5. a GitHub Release with `Sathi-X.Y.Z.dmg` and `Sathi.dmg`

The tag push builds the DMG and creates the release through `.github/workflows/release.yml`. The website download button links to `releases/latest/download/Sathi.dmg`, so it always gets the newest DMG.

Ask before every commit, push, and tag.

## 1. Before the release

1. `git status` is clean except for files the user keeps out on purpose (for example `Feature.md`).
2. `./scripts/lint.sh` and `./scripts/test.sh` pass. Show the last lines.
3. The last CI run on `main` is green: `gh run list --workflow ci.yml --limit 1`.
4. If features or the UI changed since the last release, run skill `sathi-website`. It updates the website, the screenshots, and `README.md`.
5. For UI, timer, or window changes: `./build.sh --install`, then `./scripts/perf.sh` passes.

## 2. Pick the version

Use semantic versions `MAJOR.MINOR.PATCH`:

| Change since the last tag | Bump |
|---|---|
| Only fixes, copy, or docs | PATCH |
| A new feature, setting, or buddy | MINOR |
| Saved data that an older version cannot read, or a full redesign | MAJOR |

List the changes: `git log --oneline $(git describe --tags --abbrev=0)..HEAD`.

## 3. Bump and write the changelog

1. Set the version and raise the build number by 1:
   ```sh
   /usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString X.Y.Z" -c "Set CFBundleVersion <build + 1>" Resources/Info.plist
   ```
2. In `CHANGELOG.md`, move the `[Unreleased]` items to a new `## [X.Y.Z] - YYYY-MM-DD` section. Use `### Added`, `### Changed`, `### Fixed`. Write for users: what they see, not how the code changed. Update the compare links at the end of the file.
3. In `site/index.html`, set the JSON-LD `"softwareVersion"`, the hero `.dl-meta` line, and the install card `<h3>`. `./scripts/check-site.sh` fails if `softwareVersion` does not match `Info.plist`.

## 4. Commit, merge, and tag

A hook blocks Claude's commits on `main`. Work on a branch, open a PR, and let the user merge it. Give each command that touches `main` to the user with the `!` prefix.

1. On the branch: `git add Resources/Info.plist CHANGELOG.md site README.md` and commit `chore(release): X.Y.Z`.
2. Push the branch and open a PR: `gh pr create --fill`. Wait for CI. The user merges.
3. After the merge, the user tags `main`:
   ```
   ! git checkout main && git pull && git tag -a vX.Y.Z -m "Sathi X.Y.Z" && git push origin vX.Y.Z
   ```

## 5. After the tag

1. Watch the workflow: `gh run list --workflow release.yml --limit 1`, then `gh run watch <id> --exit-status`.
2. Check the assets: `gh release view vX.Y.Z --json assets --jq '.assets[].name'` lists `Sathi-X.Y.Z.dmg` and `Sathi.dmg`.
3. Check the stable link: `curl -sIL https://github.com/Sumonta056/sathi-app/releases/latest/download/Sathi.dmg | grep -iE '^(HTTP|content-length)'` ends with `200`.
4. Download it and check it: `hdiutil verify` reports `VALID`, and the mounted `Sathi.app` reports the new version: `defaults read "$M/Sathi.app/Contents/Info" CFBundleShortVersionString`.
5. Check the site: `gh run list --workflow pages.yml --limit 1` is green, and the live page shows the new version.

## When the release workflow fails

| Error | Cause | Fix |
|---|---|---|
| Tag does not match Info.plist | The version bump was not on `main` before the tag | Do not move the tag. Fix `main` and release the next patch. |
| CHANGELOG.md has no section | The heading is not `## [X.Y.Z]` | Same as above. |
| Tests fail on the runner | A toolchain difference on `macos-15` | Read the log. Fix on a branch, then release the next patch. |
| `gh release create` fails with 403 | The workflow token has no write access | Check repo Settings → Actions → General → Workflow permissions: "Read and write". Then `gh run rerun <id> --failed`. |

Never delete or force-push a published tag without the user's approval of that exact action.

## Signing

The workflow makes an ad-hoc signed DMG. Users open it once with **System Settings → Privacy & Security → Open Anyway**. For a signed and notarized DMG, the user needs a paid Apple Developer account. Use skill `make-dmg` locally with `SIGN_IDENTITY` and `NOTARY_PROFILE`, then `gh release upload vX.Y.Z build/Sathi-X.Y.Z.dmg build/Sathi.dmg --clobber`.
