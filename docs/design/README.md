# Design reference

These PNG files are the Sathi 2.0 design. The `ui-verifier` agent compares the running app with them.

Source: the design canvas https://claude.ai/artifact/AgF243uMtC5H8ySBfdXx6e (version `1792854480-0aad`).
Rendered: 2026-10-25, at 1x, in the first state of each artboard, with animations stopped.

| File | Artboard | Size (pt) | Shows |
|---|---|---|---|
| `settings.png` | `Main.dc.html` | 860×620 | Settings window, Water tab |
| `reports.png` | `Stats.dc.html` | 860×620 | Reports window, Week, Water selected |
| `menu-bar.png` | `MenuBar.dc.html` | 380×560 | Menu bar popover, not paused |
| `water-bubble.png` | `WaterBubble.dc.html` | 440×470 | Water bubble, before a log |
| `reading-corner.png` | `ReadingToast.dc.html` | 720×450 | Reading corner popup on a sample desktop |
| `meditation.png` | `MeditateBubble.dc.html` | 400×500 | Meditation invite, before "Breathe with me" |

## Known differences that are correct

The app follows the decisions in `docs/ROADMAP.md`, not the canvas, where they differ:

1. The font is SF Rounded, not Nunito.
2. The Reports window has no Export button (removed in 5h).
3. `faint` text is `#7784A0`, not `#6F7C97` (contrast).
4. The sample names, dates, and numbers are design data.

## Render again

When the canvas changes, render the files again:

1. Save the artboard files and `artifact-type/dc-runtime.js` from the artifact (Artifact tool, `read` with `paths`).
2. Copy `dc-runtime.js` next to the artboards as `support.js`.
3. Serve the folder with `python3 -m http.server` and open each `.dc.html` in Chrome.
4. Stop animations with a style `*{animation:none!important;transition:none!important}`.
5. Take a screenshot at 860×620 and crop it from the top-left corner to the artboard size.
6. Update the version and date above.
