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
- **Focus:** Wave 5 — batch crop-resize preview + export wiring
- **Status:** ready (Waves 1–4 merged to `main`)
- **Last updated:** 2026-04-23

## Funnel Progress (Ralph-style)

| Funnel | Status | Gate |
|--------|--------|------|
| **Define** | ✓ | Name, positioning, proposal algorithm chosen |
| **Plan** | ✓ | IMPLEMENTATION_PLAN.md written; three decisions locked |
| **Build** | active | Waves 1–4 shipped; Waves 5–6 ahead |

## Phase Progress
```
[#############.......] 67% - 4 of 6 waves complete (clone + strip + analysis + histogram)
```

| Phase | Status | Tasks |
|-------|--------|-------|
| Discovery | ✓ | Problem framed, name chosen, algorithm (B + A fast path) chosen |
| Planning | ✓ | Reuse map, new-module sketches, 6-wave execution, 3 decisions |
| Implementation | active | Wave 1 ✓ · Wave 2 ✓ · Wave 3 ✓ · Wave 4 ✓ · Wave 5 next · Wave 6 pending |
| Polish | pending | Preferences pane + app-shell audit (Wave 6) |

## Readiness

| Dimension | Status | Notes |
|-----------|--------|-------|
| Features | 🔶 WIP | Import + analysis + histogram picker done; crop-fill export + preview badges pending |
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
- **Current branch:** `main` (Waves 1–4 merged; Wave 4 from `feature/histogram-ui`)

## Resume

Start Wave 5: batch crop-resize preview + export. Wire the sidebar "Pick as target" button to `exportSettings` and add the missing scale-fill + centre-crop path (plan §3.5 wants `.fill`; `ResizeMode` has no `.fill` case — current `RatioTargetResolver` returns `.exactSize` with a TODO comment, which letterboxes instead of filling). Adapt `BatchReviewView` → `PreviewGridView`; add `CropPreviewBadge` (dashed overlay of the crop box + ⚠ for upscales). Verified on a 217-image drop (2026-04-23): 24-bucket histogram renders, auto-pick lands on the largest bucket, readout shows target + label. See plan §3.4, §3.5 (resolver path), §4 Wave 5.

---
*Updated by Claude. Source of truth for project position.*
