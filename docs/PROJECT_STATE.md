# Project State

> **Size limit: <100 lines.** This is a digest, not an archive. Details go in session logs.

## Identity
- **Project:** AspectRatioUnifier
- **One-liner:** Analyse a set of images, group by aspect ratio, batch-conform outliers to a target the user picks
- **Tags:** macOS, SwiftUI, image-processing, photography
- **Started:** 2026-04-22

## Current Position
- **Funnel:** build
- **Phase:** implementation
- **Focus:** Wave 3 — `AspectRatioBucket` model + `RatioAnalyzer` service
- **Status:** ready (Waves 1 + 2 merged to `main`)
- **Last updated:** 2026-04-23

## Funnel Progress (Ralph-style)

| Funnel | Status | Gate |
|--------|--------|------|
| **Define** | ✓ | Name, positioning, proposal algorithm chosen |
| **Plan** | ✓ | IMPLEMENTATION_PLAN.md written; three decisions locked |
| **Build** | active | Waves 1+2 shipped; Waves 3–6 ahead |

## Phase Progress
```
[######..............] 30% - 2 of 6 waves complete (clone + strip)
```

| Phase | Status | Tasks |
|-------|--------|-------|
| Discovery | ✓ | Problem framed, name chosen, algorithm (B + A fast path) chosen |
| Planning | ✓ | Reuse map, new-module sketches, 6-wave execution, 3 decisions |
| Implementation | active | Wave 1 ✓ · Wave 2 ✓ · Wave 3 next · Waves 4–6 pending |
| Polish | pending | Preferences pane + app-shell audit (Wave 6) |

## Readiness

| Dimension | Status | Notes |
|-----------|--------|-------|
| Features | 🔶 WIP | Foundation running (import+resize+export); analysis/histogram/preview pending |
| UI/Polish | 🔶 WIP | Theme + App Shell inherited from CropBatch; sidebar is Wave-4 placeholder |
| Testing | ⚪ — | Needs mixed-ratio fixture set |
| Docs | ✓ | Directions, plan, decisions, CLAUDE.md all current |
| Distribution | ⚪ — | Later (DMG + Sparkle feed). `SUFeedURL` blanked until a feed exists. |

## Validation Gates
- [x] **Define → Plan**: UX (histogram picker) + reuse strategy agreed (2026-04-22)
- [x] **Plan → Build**: Xcode project scaffolded via CropBatch clone-rename; unused modules stripped (2026-04-23)
- [ ] **Build → Ship**: Analysis works on real 35mm-scan archive; batch export verified

## Active Decisions
- 2026-04-22: Positioning — specialist app, not a CropBatch mode
- 2026-04-22: Target-proposal — B (histogram) primary + A (auto) fast path
- 2026-04-22: Code reuse — clone-rename CropBatch (cookbook §34)
- 2026-04-23: Bucketing tolerance — ±1%, user-adjustable in Preferences (Wave 6)
- 2026-04-23: Tie-break — named-preset closeness → ±0.5% sub-bucket → ratio order
- 2026-04-23: Upscale policy — flag + user-deselect (default include)

All entries in `decisions.md`.

## Blockers

None.

## Open Questions

None currently — the three originally blocking were all decided 2026-04-23.

## Context
- **Origin:** user's own 35mm-film archive — consistent source (all 3:2), inconsistent scans from 20+ years ago
- **Sibling app lifted from:** `../CropBatch` (mature macOS app, same author)
- **Current branch:** `main` (Waves 1+2 merged from `feature/clone-rename` + `feature/strip-unused`)

## Resume

Start Wave 3: create `Models/AspectRatioBucket.swift` + `Services/RatioAnalyzer.swift`. Use `CGImageSourceCopyPropertiesAtIndex` with `kCGImagePropertyPixelWidth`/`Height` for metadata-only reads (no decode). Bucket by ±1% tolerance (from `Config.swift`, default value 0.01). Verify via `print()` on import before wiring UI. See plan §3.1–§3.2 and §4 Wave 3.

---
*Updated by Claude. Source of truth for project position.*
