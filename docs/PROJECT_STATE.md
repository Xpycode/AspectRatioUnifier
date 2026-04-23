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
- **Focus:** Wave 6 + 6.5 shipped — resize/mismatch/thumb-strip pruned, opaque toolbar with smart trash, ratio-filter chips replace zoom, grid shows per-thumb ratio labels + ratio-ascending sort. Next: Wave 7 (unified export dialog + target-size-strategy min/median/max).
- **Status:** ready (Waves 1–6.5 merged to `main`)
- **Last updated:** 2026-04-23

## Funnel Progress (Ralph-style)

| Funnel | Status | Gate |
|--------|--------|------|
| **Define** | ✓ | Name, positioning, proposal algorithm chosen |
| **Plan** | ✓ | IMPLEMENTATION_PLAN.md written; three decisions locked |
| **Build** | active | Waves 1–4 shipped; Waves 5–6 ahead |

## Phase Progress
```
[##################..] 92% - 6.5 of 7 waves complete (analysis + histogram + preview/export + pruning + filter/labels)
```

| Phase | Status | Tasks |
|-------|--------|-------|
| Discovery | ✓ | Problem framed, name chosen, algorithm (B + A fast path) chosen |
| Planning | ✓ | Reuse map, new-module sketches, wave execution plan, decisions |
| Implementation | active | Waves 1–6.5 ✓ · Wave 7 (unified export dialog) next |
| Polish | active | Toolbar + sidebar pruning shipped; Preferences pane + shell-check audit still open |

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

Waves 6 + 6.5 shipped on `main` (commits `905eb3a`, `462a510`). Pruned `ResizeMode`/`ResizeSettings`/`calculateResizedSize`/`resize`/mismatch-panel/`ThumbnailStripView`/`ExportSettingsView`; default suffix `_ratioed`; opaque graphite toolbar; smart trash; `RatioFilterChips` replace `ZoomPicker` with multi-select AND filter; grid sorts ascending by ratio + shows per-thumb capsule chip. Next: Wave 7 — unified export dialog (folder picker, format/quality/suffix/naming, upscale+downscale toggles moved into the preview sheet) + target-size-strategy picker (min / median / max) driving `RatioTargetResolver`. See conversation of 2026-04-23 for accumulated design context.

---
*Updated by Claude. Source of truth for project position.*
