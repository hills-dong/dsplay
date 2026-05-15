# DSPlay Logo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder app icon, web header wordmark, and menu bar status item with a unified "editorial serif D + red period" mark, matching the existing UI aesthetic.

**Architecture:** A single Swift renderer (`scripts/make-icon.swift`) emits all PNG variants (app icon large, app icon small, menu bar template). A bash orchestrator (`scripts/make-icon.sh`) drives the renderer multiple times, downscales as needed, and assembles `AppIcon.icns` + the menu bar PNG. The Swift app then loads the menu bar PNG from its resource bundle. The web header gets a one-line change to colorize the wordmark's period.

**Tech Stack:**
- Swift + AppKit (NSImage / NSBezierPath / NSFont) for raster rendering
- `sips` + `iconutil` for downscaling and `.icns` packaging
- SolidJS + Vite for the web side
- Vitest for the web test

---

## File Map

| File | Status | Responsibility |
|---|---|---|
| `scripts/make-icon.swift` | Rewrite | Stateless renderer. Accepts `--variant {app-large\|app-small\|statusbar} --size N --output PATH`, writes one PNG. |
| `scripts/make-icon.sh` | Rewrite | Orchestrator: invokes the renderer for each variant, downscales, packages `.icns`, copies the status bar PNG into `DSPlay/Resources/`. |
| `DSPlay/Resources/AppIcon.icns` | Regenerated | Output artifact (binary blob, committed). |
| `DSPlay/Resources/StatusItem.png` | Create | 44 × 44 px menu bar template image (transparent bg, black serif "D"). |
| `Package.swift` | Modify | Add `.copy("Resources/StatusItem.png")` to the resources list. |
| `DSPlay/System/StatusItemController.swift` | Modify line 23–25 | Load `StatusItem.png` from bundle instead of using SF Symbol `music.note`. |
| `web/src/components/AppShell.tsx` | Modify line 45 | Wrap the implicit "." in an accent-colored span. |
| `web/src/components/AppShell.test.tsx` | Create | Vitest: assert the wordmark renders the red period. |

---

## Task 1: Web header — wordmark gets a red period

**Files:**
- Modify: `web/src/components/AppShell.tsx:45`
- Create: `web/src/components/AppShell.test.tsx`

- [ ] **Step 1: Write the failing test**

Create `web/src/components/AppShell.test.tsx`:

```tsx
import { describe, it, expect } from "vitest";
import { render } from "@solidjs/testing-library";
import { Router } from "@solidjs/router";
import AppShell from "./AppShell";

describe("AppShell wordmark", () => {
  it("renders DSPLAY with an accent-colored period", () => {
    const { container } = render(() => (
      <Router>
        <AppShell />
      </Router>
    ));
    const wordmark = container.querySelector("header span.serif");
    expect(wordmark?.textContent).toBe("DSPLAY.");
    const period = wordmark?.querySelector("span");
    expect(period?.textContent).toBe(".");
    expect(period?.getAttribute("style") ?? "").toMatch(/color\s*:\s*var\(--accent\)/);
  });
});
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
cd /Users/bytedance/Documents/projects/dsplay/web && pnpm test -- AppShell.test
```

Expected: FAIL — either the inner `<span>` doesn't exist yet, or the textContent is "DSPLAY" not "DSPLAY.".

- [ ] **Step 3: Apply the wordmark change**

In `web/src/components/AppShell.tsx`, find line 45:

```tsx
          <span class="serif" style="font-size:22px; font-weight:700; letter-spacing:-0.02em;">DSPLAY</span>
```

Replace with:

```tsx
          <span class="serif" style="font-size:22px; font-weight:700; letter-spacing:-0.02em;">DSPLAY<span style="color:var(--accent)">.</span></span>
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
cd /Users/bytedance/Documents/projects/dsplay/web && pnpm test -- AppShell.test
```

Expected: PASS.

- [ ] **Step 5: Run the full web suite to catch regressions**

```bash
cd /Users/bytedance/Documents/projects/dsplay/web && pnpm test
```

Expected: all tests pass (the pre-existing `auth.test.ts` and `player.test.ts` continue passing).

- [ ] **Step 6: Commit**

```bash
git add web/src/components/AppShell.tsx web/src/components/AppShell.test.tsx
git commit -m "feat(web): accent-colored period in DSPLAY wordmark"
```

---

## Task 2: Rewrite the Swift renderer with three variants

**Files:**
- Rewrite: `scripts/make-icon.swift`

- [ ] **Step 1: Replace `scripts/make-icon.swift` with the new renderer**

Full file contents:

```swift
import AppKit
import Foundation

// Renders a single PNG for one of three brand variants. The bash
// orchestrator calls this multiple times, then downscales / packages as
// needed.
//
// Usage:
//   swift scripts/make-icon.swift --variant {app-large|app-small|statusbar} \
//                                 --size N --output PATH
//
//  app-large : square paper-on-rounded-rect with two hairline rules + a
//              big serif "D" + a red period. Used as the master for the
//              128/256/512/1024 slots of the .icns iconset.
//  app-small : same square + paper bg but the hairlines are dropped and
//              the "D." is enlarged so the dot still reads at 16px.
//              Used as the master for the 16/32/64 slots.
//  statusbar : transparent background, plain black serif "D" (no dot —
//              menu bar template images are monochrome). Used as the
//              menu bar icon.
//
// All coordinates below are TOP-DOWN (y=0 is at the top of the canvas),
// because `lockFocusFlipped(true)` sets up a flipped graphics context.
// Numeric constants are fractions of 1024 — tweak them and re-run to taste.

// ----- argument parsing -----
var variant: String?
var sizeArg: Double?
var outPath: String?
var args = CommandLine.arguments.dropFirst().makeIterator()
while let arg = args.next() {
    switch arg {
    case "--variant":  variant = args.next()
    case "--size":     sizeArg = args.next().flatMap { Double($0) }
    case "--output":   outPath = args.next()
    default:           break
    }
}
guard let variant, let sizeArg, let outPath else {
    FileHandle.standardError.write("usage: --variant {app-large|app-small|statusbar} --size N --output PATH\n".data(using: .utf8)!)
    exit(2)
}
let size = CGFloat(sizeArg)

// ----- font resolution -----
// Prefer Newsreader (what the web UI uses). Fall back to the system
// serif design (New York on modern macOS). Both are transitional serifs.
func serifBold(_ pointSize: CGFloat) -> NSFont {
    // 1. Newsreader (the typeface the web UI uses) if installed.
    if let f = NSFont(name: "Newsreader-Bold", size: pointSize) { return f }
    if let f = NSFont(name: "Newsreader", size: pointSize) { return f }
    // 2. New York (macOS system serif since Big Sur).
    if let f = NSFont(name: "NewYork-Bold", size: pointSize) { return f }
    // 3. Derive a serif from the system font descriptor.
    let systemBold = NSFont.systemFont(ofSize: pointSize, weight: .bold)
    if let serif = systemBold.fontDescriptor.withDesign(.serif),
       let f = NSFont(descriptor: serif, size: pointSize) { return f }
    // 4. Last-resort: system bold (sans-serif but the renderer will still
    // produce something visible — the operator should install Newsreader).
    return systemBold
}

// ----- colour tokens (match web/src/styles/theme.css) -----
let ink    = NSColor(red: 0x11/255.0, green: 0x11/255.0, blue: 0x11/255.0, alpha: 1.0)
let paper  = NSColor(red: 0xFA/255.0, green: 0xFA/255.0, blue: 0xF7/255.0, alpha: 1.0)
let accent = NSColor(red: 0xC4/255.0, green: 0x30/255.0, blue: 0x2B/255.0, alpha: 1.0)

// ----- helpers (top-down coordinates) -----

/// Draws a serif "D" so that the bounding box of the glyph is centred on
/// (centerX, centerY). The "D" has empty space below the baseline
/// (descender area), so to make the visible glyph land at centerY we
/// shift the box up by half the descender height.
func drawSerifD(centerX: CGFloat, centerY: CGFloat, fontSize: CGFloat, color: NSColor) {
    let font = serifBold(fontSize)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        // Mild negative tracking — single character so this is mostly
        // for consistency with the web wordmark.
        .kern: -fontSize * 0.02 as NSNumber,
    ]
    let text = "D" as NSString
    let bbox = text.size(withAttributes: attrs)
    // In a flipped context, origin is the top-left of the bounding rect
    // in top-down y. We centre the bbox and then nudge up by half the
    // descender (descender is negative; subtracting it nudges up here in
    // top-down coords, which is fewer y).
    let descender = font.descender   // negative
    let origin = NSPoint(
        x: centerX - bbox.width / 2,
        y: centerY - bbox.height / 2 + descender / 2
    )
    text.draw(at: origin, withAttributes: attrs)
}

func drawDot(centerX: CGFloat, centerY: CGFloat, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: NSRect(
        x: centerX - radius, y: centerY - radius,
        width: radius * 2, height: radius * 2
    )).fill()
}

func drawHairline(yTop: CGFloat, inset: CGFloat, thickness: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(rect: NSRect(
        x: inset, y: yTop, width: size - inset * 2, height: thickness
    )).fill()
}

// ----- canvas (flipped → top-down coords) -----
let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocusFlipped(true)

switch variant {
case "app-large":
    // Background: paper, 22% corner-radius rounded rect.
    let bgPath = NSBezierPath(
        roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
        xRadius: size * 0.22, yRadius: size * 0.22
    )
    paper.setFill(); bgPath.fill()

    // Hairlines (inset 100/1024 each side, thickness 3/1024).
    let ruleInset = size * (100.0/1024.0)
    let ruleThickness = max(1, size * (3.0/1024.0))
    drawHairline(yTop: size * (180.0/1024.0), inset: ruleInset, thickness: ruleThickness, color: ink)
    drawHairline(yTop: size * (841.0/1024.0), inset: ruleInset, thickness: ruleThickness, color: ink)

    // Serif "D" — centred at (0.40, 0.52) of the canvas, biased left of
    // centre so the dot fits to the right. Visible centre roughly between
    // the two hairlines.
    drawSerifD(
        centerX: size * 0.40,
        centerY: size * 0.52,
        fontSize: size * (760.0/1024.0),
        color: ink
    )

    // Red period to the right of the D, near the visual baseline.
    drawDot(
        centerX: size * 0.74,
        centerY: size * 0.72,
        radius:  size * (68.0/1024.0),
        color: accent
    )

case "app-small":
    // Same square, no hairlines, larger "D." so it survives at 16px.
    let bgPath = NSBezierPath(
        roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
        xRadius: size * 0.22, yRadius: size * 0.22
    )
    paper.setFill(); bgPath.fill()

    drawSerifD(
        centerX: size * 0.40,
        centerY: size * 0.52,
        fontSize: size * (900.0/1024.0),
        color: ink
    )
    drawDot(
        centerX: size * 0.76,
        centerY: size * 0.74,
        radius:  size * (90.0/1024.0),
        color: accent
    )

case "statusbar":
    // Transparent background, ink-black serif "D" only. The dot is
    // dropped because menu bar template images are monochrome and the
    // system will tint the whole image based on the menu bar's appearance.
    drawSerifD(
        centerX: size / 2,
        centerY: size * 0.50,
        fontSize: size * 0.88,
        color: ink
    )

default:
    img.unlockFocus()
    FileHandle.standardError.write("unknown variant: \(variant)\n".data(using: .utf8)!)
    exit(2)
}

img.unlockFocus()

// ----- encode + write -----
guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("failed to encode PNG\n".data(using: .utf8)!)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outPath))
```

- [ ] **Step 2: Smoke-run each variant**

```bash
cd /Users/bytedance/Documents/projects/dsplay
mkdir -p .build/icon-smoke
swift scripts/make-icon.swift --variant app-large --size 1024 --output .build/icon-smoke/app-large.png
swift scripts/make-icon.swift --variant app-small --size 1024 --output .build/icon-smoke/app-small.png
swift scripts/make-icon.swift --variant statusbar --size 44   --output .build/icon-smoke/statusbar.png
ls -l .build/icon-smoke/
```

Expected: all three files exist, each > 0 bytes. Open them with `open .build/icon-smoke/*.png` and eyeball — the app variants should be paper-coloured rounded squares with a black D and a red dot; the statusbar variant should be a transparent black D.

- [ ] **Step 3: Commit (renderer only — actual assets regenerate in Task 3)**

```bash
git add scripts/make-icon.swift
git commit -m "feat(icon): renderer for serif-D mark with three variants"
```

---

## Task 3: Update make-icon.sh to assemble both artifacts

**Files:**
- Rewrite: `scripts/make-icon.sh`
- Regenerate: `DSPlay/Resources/AppIcon.icns`
- Generate: `DSPlay/Resources/StatusItem.png`

- [ ] **Step 1: Replace `scripts/make-icon.sh`**

Full file contents:

```bash
#!/usr/bin/env bash
# Regenerates DSPlay/Resources/AppIcon.icns and DSPlay/Resources/StatusItem.png
# from scratch. Run once (or whenever the brand mark changes). The results
# are committed to git so normal `build.sh` runs don't need to re-render.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

WORK=".build/icon"
rm -rf "$WORK"
mkdir -p "$WORK/AppIcon.iconset"

echo "make-icon.sh: rendering app-icon masters"
swift scripts/make-icon.swift --variant app-large --size 1024 --output "$WORK/large.png"
swift scripts/make-icon.swift --variant app-small --size 1024 --output "$WORK/small.png"

echo "make-icon.sh: downscaling large master (>=128px slots)"
for sz in 128 256 512 1024; do
  sips -z "$sz" "$sz" "$WORK/large.png" --out "$WORK/L-$sz.png" >/dev/null
done

echo "make-icon.sh: downscaling small master (<=64px slots)"
for sz in 16 32 64; do
  sips -z "$sz" "$sz" "$WORK/small.png" --out "$WORK/S-$sz.png" >/dev/null
done

ISET="$WORK/AppIcon.iconset"
cp "$WORK/S-16.png"   "$ISET/icon_16x16.png"
cp "$WORK/S-32.png"   "$ISET/icon_16x16@2x.png"
cp "$WORK/S-32.png"   "$ISET/icon_32x32.png"
cp "$WORK/S-64.png"   "$ISET/icon_32x32@2x.png"
cp "$WORK/L-128.png"  "$ISET/icon_128x128.png"
cp "$WORK/L-256.png"  "$ISET/icon_128x128@2x.png"
cp "$WORK/L-256.png"  "$ISET/icon_256x256.png"
cp "$WORK/L-512.png"  "$ISET/icon_256x256@2x.png"
cp "$WORK/L-512.png"  "$ISET/icon_512x512.png"
cp "$WORK/L-1024.png" "$ISET/icon_512x512@2x.png"

iconutil -c icns "$ISET" -o "DSPlay/Resources/AppIcon.icns"
echo "make-icon.sh: wrote DSPlay/Resources/AppIcon.icns"

echo "make-icon.sh: rendering menu bar status item PNG (44px @2x source)"
swift scripts/make-icon.swift --variant statusbar --size 44 \
  --output "DSPlay/Resources/StatusItem.png"
echo "make-icon.sh: wrote DSPlay/Resources/StatusItem.png"
```

- [ ] **Step 2: Run it end-to-end**

```bash
cd /Users/bytedance/Documents/projects/dsplay
bash scripts/make-icon.sh
```

Expected output lines:
```
make-icon.sh: rendering app-icon masters
make-icon.sh: downscaling large master (>=128px slots)
make-icon.sh: downscaling small master (<=64px slots)
make-icon.sh: wrote DSPlay/Resources/AppIcon.icns
make-icon.sh: rendering menu bar status item PNG (44px @2x source)
make-icon.sh: wrote DSPlay/Resources/StatusItem.png
```

- [ ] **Step 3: Verify the artifacts**

```bash
ls -l DSPlay/Resources/AppIcon.icns DSPlay/Resources/StatusItem.png
file DSPlay/Resources/AppIcon.icns DSPlay/Resources/StatusItem.png
open DSPlay/Resources/AppIcon.icns DSPlay/Resources/StatusItem.png
```

Expected:
- `AppIcon.icns` is `Mac OS X icon` (file type), non-zero size
- `StatusItem.png` is `PNG image data, 44 x 44`
- Preview shows the brand mark correctly

- [ ] **Step 4: Commit**

```bash
git add scripts/make-icon.sh DSPlay/Resources/AppIcon.icns DSPlay/Resources/StatusItem.png
git commit -m "feat(icon): regenerate AppIcon and StatusItem from new renderer"
```

---

## Task 4: Bundle StatusItem.png into the Swift target

**Files:**
- Modify: `Package.swift`

- [ ] **Step 1: Add the resource entry**

In `Package.swift`, find the `resources:` list:

```swift
            resources: [
                .copy("Resources/WebDist"),
            ]
```

Replace with:

```swift
            resources: [
                .copy("Resources/WebDist"),
                .copy("Resources/StatusItem.png"),
            ]
```

- [ ] **Step 2: Verify the build still resolves resources**

```bash
cd /Users/bytedance/Documents/projects/dsplay
swift build
```

Expected: builds cleanly. (`swift build` doesn't load the resource at compile time; this step just confirms `Package.swift` is well-formed.)

- [ ] **Step 3: Commit**

```bash
git add Package.swift
git commit -m "build: bundle StatusItem.png as Swift target resource"
```

---

## Task 5: Status item loads the bundled PNG instead of SF Symbol

**Files:**
- Modify: `DSPlay/System/StatusItemController.swift:23-29`

- [ ] **Step 1: Replace the image-setup block**

In `DSPlay/System/StatusItemController.swift`, find lines 23–29:

```swift
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "DSPlay")
            button.image?.isTemplate = true
            button.toolTip = "DSPlay"
            button.target = self
            button.action = #selector(handleClick(_:))
        }
```

Replace with:

```swift
        if let button = item.button {
            button.image = Self.loadStatusItemImage()
            button.toolTip = "DSPlay"
            button.target = self
            button.action = #selector(handleClick(_:))
        }
```

Then add this static method to the `StatusItemController` class, right before the closing `}` of the class:

```swift
    /// Loads StatusItem.png from whichever bundle layout we're running in.
    /// Mirrors the multi-path strategy in WebViewController.resolveWebDistDirectory.
    private static func loadStatusItemImage() -> NSImage? {
        let candidates: [URL] = [
            // 1. swift-bundler layout: nested SwiftPM bundle.
            Bundle.main
                .url(forResource: "DSPlay_DSPlay", withExtension: "bundle")
                .flatMap { Bundle(url: $0) }?
                .url(forResource: "StatusItem", withExtension: "png"),
            // 2. SwiftPM module accessor (used by `swift run` / tests).
            Bundle.module.url(forResource: "StatusItem", withExtension: "png"),
            // 3. Flat in Bundle.main.
            Bundle.main.url(forResource: "StatusItem", withExtension: "png"),
        ].compactMap { $0 }

        for url in candidates {
            if let img = NSImage(contentsOf: url) {
                img.size = NSSize(width: 18, height: 18)  // 18pt is the conventional menu bar icon size
                img.isTemplate = true
                return img
            }
        }
        NSLog("[DSPlay] StatusItem.png not found in any bundle path; falling back to SF Symbol")
        let fallback = NSImage(systemSymbolName: "music.note", accessibilityDescription: "DSPlay")
        fallback?.isTemplate = true
        return fallback
    }
```

- [ ] **Step 2: Build the app and verify the menu bar visually**

```bash
cd /Users/bytedance/Documents/projects/dsplay
bash scripts/run.sh
```

Expected: app launches, menu bar (top-right) shows a black serif "D" instead of the SF Symbol music note. Click it — the popover still works.

- [ ] **Step 3: Verify no fallback log line appeared**

In a separate terminal:

```bash
log show --predicate 'process == "DSPlay" AND eventMessage CONTAINS "StatusItem.png not found"' --last 5m
```

Expected: no matching log entries (i.e., the bundle path resolved successfully).

- [ ] **Step 4: Commit**

```bash
git add DSPlay/System/StatusItemController.swift
git commit -m "feat(menubar): use bundled StatusItem image instead of SF Symbol"
```

---

## Task 6: End-to-end visual verification

**Files:** none modified.

- [ ] **Step 1: Clean build + relaunch from /Applications**

```bash
cd /Users/bytedance/Documents/projects/dsplay
bash scripts/build.sh
open /Applications/DSPlay.app
```

- [ ] **Step 2: Eyeball each surface**

Check each of these and confirm the new mark renders correctly:

1. **Dock icon** — paper-coloured rounded square, hairlines top/bottom, big serif "D" with a red dot to its right.
2. **Cmd+Tab switcher** — same icon, smaller. Should still read as "D." (hairlines may or may not survive depending on size; small variant kicks in below 128px).
3. **Finder → /Applications → DSPlay.app** — same icon at icon view size; the .icns mounted.
4. **Web header** (top of the app window) — wordmark reads `DSPLAY` followed by a red `.`.
5. **Menu bar (top-right of screen)** — black serif "D" only, auto-tinted by the system. Click it → mini-player popover appears as before.

If any surface still shows the old icon, force Launch Services to refresh:

```bash
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
  -f /Applications/DSPlay.app
killall Dock
```

- [ ] **Step 3: No-op — this task ends in verification, not a commit.**

If any surface looks wrong, return to the relevant task (renderer = Task 2, orchestrator = Task 3, web = Task 1, menu bar code = Task 5) and adjust.

---

## Done When

- All five surfaces (dock, switcher, Finder, web header, menu bar) show the new mark.
- `swift build` + `swift test` + `pnpm test` all pass.
- Repo is clean (`git status` shows no uncommitted changes).
