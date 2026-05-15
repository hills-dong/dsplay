# DSPlay Logo Design

**Date:** 2026-05-15
**Status:** Approved, pending implementation plan

## Goal

A logo system that matches the existing "editorial / newspaper" UI aesthetic, applied consistently across:

1. **macOS app icon** (`DSPlay/Resources/AppIcon.icns` — dock, Finder, Launchpad)
2. **Web header wordmark** (`web/src/components/AppShell.tsx`)
3. **Menu bar status item** (`DSPlay/System/StatusItemController.swift`)

Current state:
- App icon: black rounded square + white `♪` glyph (does not match the UI).
- Web header: plain text "DSPLAY" wordmark in Newsreader 700.
- Menu bar: SF Symbol `music.note`, system-tinted template image.

## Visual Language (already established by the UI)

| Token        | Value                              |
| ------------ | ---------------------------------- |
| Ink          | `#111111`                          |
| Paper        | `#FAFAF7` (the warm white actually rendered behind the vibrancy layer) |
| Accent red   | `#c4302b`                          |
| Mute gray    | `#888888`                          |
| Display face | Newsreader / Source Serif 4, 700, letter-spacing `-0.02em` |
| Label face   | system sans, 11px, `letter-spacing: 0.15em`, uppercase |
| Hairline rule | 1px ink, horizontal               |

## Core Mark Concept

A serif "D" with a red period:

> **D.**

- The "D" is set in Newsreader (or Source Serif 4 as fallback), weight 700, ink `#111`.
- The period is a circle in accent red `#c4302b`, sized like a serif period (≈ 8% of the cap height), positioned at the baseline to the right of the D.
- Three readings overlap: (1) abbreviation of "DSPLAY.", (2) the editorial full stop that the wordmark already implies, (3) a stylus dropping onto a record.

## Application: App Icon

**Canvas:** 1024 × 1024 PNG, rounded square mask with corner radius `0.22 * size` (matches current implementation).

**Large composition** (used for the 128, 256, 512, 1024 slots of the iconset):

```
┌─────────────────────────┐
│                         │
│ ──────────────────────  │  ← top hairline rule (1024px: 3px tall)
│                         │
│                         │
│         D  ●            │  ← serif D (ink), red dot (accent) at baseline
│                         │
│                         │
│ ──────────────────────  │  ← bottom hairline rule
│                         │
└─────────────────────────┘
```

- Background: paper `#FAFAF7` (the same warm white the web UI sits on).
- Hairlines: ink `#111`, 1024px width spans 824px (inset 100px each side), 3px tall.
- "D": Newsreader 700, font-size ~780px, baseline ~730px, horizontally biased left-of-center so the dot has room.
- Dot: circle, radius ~68px (≈ 6.6% of canvas), fill `#c4302b`, vertically aligned to the D's baseline.

**Small composition** (used for 16, 32, and the @2x of those — i.e., the 16, 32, 64 px PNGs in the iconset):

- Same background.
- Drop the hairlines (they become 1-pixel noise at this scale).
- Scale the "D." to fill more of the canvas (~90% of width).
- Dot remains red. At 16px the dot is ~1 device-pixel; that's acceptable — it reads as a single colored speck, which is the brand DNA we want even when tiny.

The cutoff is **64px and below = small; 128px and above = large.**

## Application: Web Header Wordmark

In `web/src/components/AppShell.tsx`, the header currently reads:

```tsx
<span class="serif" style="font-size:22px; font-weight:700; letter-spacing:-0.02em;">DSPLAY</span>
```

Change to:

```tsx
<span class="serif" style="font-size:22px; font-weight:700; letter-spacing:-0.02em;">
  DSPLAY<span style="color:var(--accent)">.</span>
</span>
```

That's the entire change. No icon mark next to the wordmark — the wordmark *is* the mark in this context. The red period is small (matches the font's natural period size), positioned by the typeface's own metrics.

## Application: Menu Bar Status Item

macOS menu bar template images must be monochrome (the system tints them based on light/dark menu bar). So the red dot can't survive verbatim. Two viable approaches:

**A. Template "D" without the dot.** Render a 22pt × 22pt serif "D" in black on transparent, mark `isTemplate = true`. The dot is dropped. Pro: respects system theming. Con: loses brand color.

**B. Non-template colored image.** Render the full "D." with red dot. `isTemplate = false`. Pro: brand color preserved. Con: doesn't auto-tint in dark menu bar — but on macOS the menu bar always has high enough contrast that ink black on it is readable in both modes (system menu bar uses near-black/near-white backgrounds).

**Decision:** Approach A. The menu bar is the *most* system-integrated surface and behaving like a system icon (auto-tinting) is more valuable than preserving the dot. The "D" alone still reads as DSPlay.

Implementation:
- Add `DSPlay/Resources/StatusItem.png` (44 × 44 px, transparent background, black serif "D", centered) and `StatusItem@2x.png` (88 × 88). Or single PNG using NSImage size hint — pick what fits the existing resource pipeline.
- In `StatusItemController.swift:24`, replace:
  ```swift
  button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "DSPlay")
  button.image?.isTemplate = true
  ```
  with a load from the bundle that resolves the new asset. Keep `isTemplate = true`.

## Implementation Surface

| File                                                       | Change                                                                                  |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `scripts/make-icon.swift`                                  | Replace renderer: paper bg, hairlines, serif D + red dot. Accept a `--size variant` flag to switch between large/small composition. |
| `scripts/make-icon.sh`                                     | Call the renderer twice — once for large (used for 128/256/512/1024 slots), once for small (used for 16/32 slots). |
| `DSPlay/Resources/AppIcon.icns`                            | Regenerated artifact, committed.                                                       |
| `web/src/components/AppShell.tsx`                          | Wrap the period in `<span style="color:var(--accent)">.</span>` (line 45).             |
| `DSPlay/Resources/StatusItem.png` (and `@2x`)              | New asset(s) for menu bar.                                                              |
| `DSPlay/System/StatusItemController.swift`                 | Switch from SF Symbol to bundle image load (line 24).                                  |
| `Package.swift` (if needed)                                | Make sure new PNG resources are bundled.                                                |

## Out of Scope

- DMG background, marketing banners, README hero image, favicon for any web view — not needed for this task. The same mark can be reused later without redesign.
- Switching the icon canvas from a rounded rectangle to Apple's official squircle (superellipse) shape. The existing 22% rounded rect is close enough and changing it is a separate concern.
- Changing the four NowPlaying skins. They have their own internal language ("Editorial" / "Terminal CRT" / "Winamp 90s" / "Vinyl") and the logo doesn't need to invade them.

## Open Questions (resolved during brainstorming)

- **Paper vs. ink app-icon background?** → Paper. User chose C4 (paper + hairlines) over C3 (ink reverse) explicitly.
- **Mark alongside wordmark in web header?** → No. User chose W1: just give the existing wordmark a red period.
- **Where does the dot live?** → Baseline period position, right of the D, sized like a serif period. (C1/C4 composition.)

## Trade-offs Acknowledged

- **Dot at 16 px** will be roughly one device pixel of red — visually a colored speck, not a clean circle. Acceptable: brand DNA survives even when blurred, and 16px is rarely the user's main encounter with the icon (Finder sidebar lists, etc.).
- **Hairlines disappear below 64 px** by design. The mark works without them; they're an editorial flourish that earns its keep only at sizes large enough to show typographic detail.
- **Paper bg in the dock** is softer than the current black icon. It will sit "quieter" among colorful peers, but it's intentionally consistent with the rest of the brand and unambiguously identifies the app.
