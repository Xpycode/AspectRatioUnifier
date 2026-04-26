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
- **Focus:** Wave 7 shipped 2026-04-26 — target-size-strategy Picker (Min/Median/Max, default Min) in HistogramView readout · grid sort feature (Aspect Ratio / Width / Height / Megapixels, persisted to UserDefaults, Picker-in-Menu in toolbar) · CropPreviewBadge overlay now respects `.fit`-rendered image bounds (latent bug surfaced under wide targets). Min hunt workflow validated on the 530-image archive — exclusion of small outliers grows the Min target as designed. Next: Wave 7.5 (surface the binding image with [Reveal] [Exclude] buttons in the sidebar — fully planned, ~90 LOC, see 2026-04-26 session log).
- **Status:** ready (Waves 1–7 merged to `main`)
- **Last updated:** 2026-04-26

## Funnel Progress (Ralph-style)

| Funnel | Status | Gate |
|--------|--------|------|
| **Define** | ✓ | Name, positioning, proposal algorithm chosen |
| **Plan** | ✓ | IMPLEMENTATION_PLAN.md written; three decisions locked |
| **Build** | active | Waves 1–4 shipped; Waves 5–6 ahead |

## Phase Progress
```
[####################] 100% main waves · Wave 7.5 (binding-image surfacing) is opt-in polish
```

| Phase | Status | Tasks |
|-------|--------|-------|
| Discovery | ✓ | Problem framed, name chosen, algorithm (B + A fast path) chosen |
| Planning | ✓ | Reuse map, new-module sketches, wave execution plan, decisions |
| Implementation | ✓ | Waves 1–7 shipped · Wave 7.5 (binding-image surfacing) planned, not yet built |
| Polish | active | Toolbar/sidebar pruning, Min strategy, sort UX shipped; Preferences pane + shell-check audit still open |

## Readiness

| Dimension | Status | Notes |
|-----------|--------|-------|
| Features | 🔶 WIP | Import + analysis + histogram picker + crop-fill export + preview badges done; needs live verification on 529-image archive |
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
- 2026-04-23: Ratio target — dedicated `ExportSettings.ratioTarget: CGSize?` (not a new `ResizeMode.fill` case); pipeline branches on non-nil
- 2026-04-23: Exclusion state — `AppState.excludedImageIDs: Set<UUID>` (survives re-analysis; single source of truth)
- 2026-04-23: Histogram commitment — bar tap auto-commits; no separate "Pick as target" button
- 2026-04-25: Bucketing algorithm — constrained agglomerative (single-link chain `bucketTolerance=0.01` + complete-link diameter cap `bucketMaxSpan=0.05`)
- 2026-04-25: Chip strip — top-10 by count on analysis, MRU rotation via +menu replaces rightmost slot, position stable across filter toggles
- 2026-04-25: Named-preset snap widened 0.2% → 2.5%, sized to ~half the bucketMaxSpan so consolidation-drifted means still snap to "3:2"/"4:3"/etc. labels
- 2026-04-25: Wave 7 default target-size strategy will be "Min" (largest non-upscaling size) — matches the photographer-cleaning-archives mindset
- 2026-04-26: Wave 7 — three target-size strategies (Min/Median/Max) shipped. Min/Max are global properties of the included image set; Median is bucket-local. Inscribed-rectangle math drives Min/Max.
- 2026-04-26: Grid sort — four dimensions (Aspect Ratio / Width / Height / Megapixels) + reverse toggle, persisted to UserDefaults. `targetSizeStrategy` deliberately NOT persisted (opinionated default).
- 2026-04-26: CropPreviewBadge overlay must respect `.fit`-rendered image bounds, not full badge frame (latent bug, only obvious at extreme aspect mismatches).

All entries in `decisions.md`.

## Blockers

None.

## Open Questions

None currently — the three originally blocking were all decided 2026-04-23.

## Context
- **Origin:** user's own 35mm-film archive — consistent source (all 3:2), inconsistent scans from 20+ years ago
- **Sibling app lifted from:** `../CropBatch` (mature macOS app, same author)
- **Current branch:** `main` (Waves 1–4 merged; Wave 4 from `feature/histogram-ui`)

## Resume

Wave 7 + 6.5 + earlier all on `main`. The two pieces of Wave 7 shipped on 2026-04-26: target-size-strategy Picker in the sidebar (Min/Median/Max, default Min) and the grid sort feature (four dimensions, persisted to UserDefaults, Picker-in-Menu in the toolbar). Crop overlay bug also fixed. Wave 7's *other* originally-planned half — unified export dialog consolidation (folder picker + format/quality/suffix/naming + upscale toggles all into the preview sheet) — is still open but lower-priority. Wave 7.5 (surface the binding image with [Reveal] [Exclude] buttons in HistogramView readout, ScrollViewReader integration in ImageGridView) is fully planned in the 2026-04-26 session log; ~90 LOC, ready to ship next session.

---
*Updated by Claude. Source of truth for project position.*
