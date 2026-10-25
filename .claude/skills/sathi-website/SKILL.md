---
name: sathi-website
description: Update the GitHub Pages website (site/), its screenshots, its SEO tags, and README.md after a user-visible change ships. Use after any feature, buddy, setting, window, or copy change, when asked to "update the website", "update the README", "refresh screenshots", "improve SEO", or "add this feature to the site", and before a release.
---

# Update the website, screenshots, and README

The website lives in `site/`. It is static HTML and CSS with no build step. `.github/workflows/pages.yml` deploys `site/` to `https://sumonta056.github.io/sathi-app/` after CI passes on `main`.

Sathi is a native app, so the site has no live demo. It shows screenshots that a test renders from the real SwiftUI views with sample data.

Plan the edits and get approval before you change files. Ask before you commit.

## 1. Find what changed

- `git log --oneline <last site or README commit>..HEAD` and `CHANGELOG.md` → `[Unreleased]` list the user-visible changes.
- `git diff <that commit>..HEAD -- .claude/rules/business-logic.md Sources/SathiUI/Features/` shows new behavior.
- Ignore tests, refactors, and CI. The site and README describe what a user sees.

## 2. Map each change to the places it shows

| Area changed | Website (`site/index.html`) | Screenshot | README.md section |
|---|---|---|---|
| Menu bar popover | hero | `menu-bar.png` | top image |
| Water bubble, sip bottle | feature "A water reminder…", buddy card "Fota" | `water-bubble.png` | The buddies |
| Reading corner popup, timer pill | feature "A reading popup…", buddy card "Boi" | `reading-corner.png` | The buddies |
| Meditation invite, breathing | feature "Guided breathing…", buddy card "Shanti" | `meditation.png` | The buddies |
| Reports window | feature "Reports…" | `reports.png` | Reports and settings |
| Settings window | feature "Settings…" | `settings.png` | Reports and settings |
| Strictness, lock, pause | section `#escalation` | — | Reminders that escalate |
| Saved files | section `#privacy` | — | Privacy |
| Install steps, Gatekeeper | section `#install`, FAQ | — | Install |
| A new buddy | new `.buddy` card, new `.feature` block (alternate `flip`), FAQ if needed | new `<name>.png` | The buddies |
| Version | JSON-LD `softwareVersion`, hero `.dl-meta`, install card `<h3>` | — | Changelog (owned by `sathi-release`) |

## 3. Render the screenshots

Never screenshot the real app. It shows the user's name and history. `Tests/SathiUITests/WebsiteShots.swift` renders each view with fixed sample data ("Alex", 25 days of history, 26 March 2026) in an off-screen `NSHostingView` at 2x:

```sh
SATHI_SHOTS="$PWD/site/screenshots" swift test --filter WebsiteShots
```

The suite runs only when `SATHI_SHOTS` is set. It skips in normal test runs.

- A new window or view: add a `@Test` to `WebsiteShots` that calls `save(<View>, "<name>", h)`.
- A view that needs other sample data: change `sampleEvents()` or `harness()`. Keep the data realistic: a streak, a few missed days.
- The water bubble headline is random. Render again if the line looks odd.

Read each new image. It shows the feature, has no cut text, and has no yellow "not available" boxes (an AppKit control that did not render).

Then update the `width` and `height` of the matching `<img>` in `site/index.html` to the new pixel size: `sips -g pixelWidth -g pixelHeight site/screenshots/<name>.png`.

## 4. Make the social image again

`site/og.png` (1200 × 630) is the link preview on Google, Slack, and X. Make it again when `menu-bar.png` or `water-bubble.png` changes:

```sh
P=$(mktemp -d <scratchpad>/chrome.XXXXXX)
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --user-data-dir="$P" \
  --hide-scrollbars --allow-file-access-from-files --window-size=1200,630 --virtual-time-budget=4000 \
  --screenshot="$PWD/site/og.png" "file://$PWD/scripts/og-card.html"
```

Read the image. The bubble must not cover the headline.

## 5. Write the text

- The site and the README use the same words for the same thing. Sentence case, plain verbs, short sentences.
- Each feature block on the site: 1 `<h3>`, 1 or 2 sentences, at most 3 list items.
- Every README image and repo link is an absolute URL (`https://raw.githubusercontent.com/Sumonta056/sathi-app/main/...` or `https://github.com/Sumonta056/sathi-app/blob/main/...`).
- Every image gets a real `alt` text that says what the picture shows.
- Check every claim against the code and `.claude/rules/business-logic.md`. Never list a removed feature (for example, CSV export has no menu now).
- An FAQ answer lives in 2 places: the visible `<details>` and the `FAQPage` JSON-LD in `<head>`. Keep them word for word the same.

## 6. SEO rules

- `<title>` and `<meta name="description">` name the search terms: "water reminder", "Mac", "menu bar", "reading", "meditation", "free". Keep the title under 65 characters and the description under 160.
- If the change alters what the product is, update `description`, `og:description`, `twitter:description`, and the JSON-LD `description`.
- A new page needs a `<loc>` in `site/sitemap.xml`. A new screenshot needs an `<image:image>` there. Update `<lastmod>`.
- Keep the page fast: no JavaScript framework, `loading="lazy"` on every image below the hero, `width` and `height` on every image.
- Google Search Console (owner: the user) indexes the site. After a big change, ask the user to submit `sitemap.xml` again there.

## 7. Check

1. `./scripts/check-site.sh` prints `Site OK`. CI runs it too.
2. Serve the site: `python3 -I -m http.server 8812 --bind 127.0.0.1 -d site`.
3. Use Chrome DevTools MCP. Open your own tab and close it at the end.
   1. At 1440 × 900 and at 390 × 844: no sideways scroll, every image loads, the console has no errors.
   2. Run `lighthouse_audit` for mobile and desktop. SEO, Accessibility, and Best Practices must be 100.
4. Say which screenshots changed and what you could not check.

Ask before you commit. Use `docs(site): ...` for text and screenshots, `feat(site): ...` for new site behavior, and `docs(readme): ...` for README-only changes.
