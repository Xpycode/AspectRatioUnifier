# Project State

> **Size limit: <100 lines.** This is a digest, not an archive. Details go in session logs.

## Identity
- **Project:** AspectRatioUnifier
- **One-liner:** Analyse a set of images, group by aspect ratio, batch-conform outliers to a target the user picks
- **Tags:** macOS, SwiftUI, image-processing, photography
- **Started:** 2026-04-22

## Current Position
- **Funnel:** define
- **Phase:** discovery
- **Focus:** Scaffold Xcode project by lifting the shell + pipelines from CropBatch (sibling folder)
- **Status:** ready
- **Last updated:** 2026-04-22

## Funnel Progress (Ralph-style)

| Funnel | Status | Gate |
|--------|--------|------|
| **Define** | active | Name, positioning, proposal algorithm chosen |
| **Plan** | pending | Xcode project structure + analysis-step design |
| **Build** | pending | — |

## Phase Progress
```
[##..................] 10% - Docs scaffolded; no code yet
```

| Phase | Status | Tasks |
|-------|--------|-------|
| Discovery | active | Problem framed, name chosen, algorithm (B + A fast path) chosen |
| Planning | pending | Xcode clone-rename, module list, histogram UI sketch |
| Implementation | pending | — |
| Polish | pending | — |

## Readiness

| Dimension | Status | Notes |
|-----------|--------|-------|
| Features | ⚪ — | Analysis + histogram picker + batch crop-resize |
| UI/Polish | ⚪ — | App Shell Standard; reuse CropBatch Theme |
| Testing | ⚪ — | Will need fixture image set with mixed ratios |
| Docs | 🔶 WIP | Directions scaffolded; CLAUDE.md written |
| Distribution | ⚪ — | Later: DMG + appcast like CropBatch |

## Validation Gates
- [x] **Define → Plan**: Core UX (histogram picker) and code-reuse strategy agreed
- [ ] **Plan → Build**: Xcode project scaffolded, modules scoped
- [ ] **Build → Ship**: Analysis works on real 35mm-scan archive; batch export verified

## Active Decisions
- 2026-04-22: Target-proposal algorithm — **B (histogram picker)** primary, **A (auto mode + median)** as one-click fast path
- 2026-04-22: Code-reuse strategy — lift Xcode project from CropBatch, don't start from zero
- 2026-04-22: Name finalised — `AspectRatioUnifier` (was `ResizerAutomatic`)

## Blockers

None.

## Open Questions
- Bucketing tolerance: ±1% or ±0.5% for grouping aspect ratios
- Tie-break when two buckets are equally populated
- Upscale policy when target exceeds some source dimensions (warn / refuse / allow)

## Context
- **Origin:** user's own 35mm-film archive — consistent source (all 3:2), inconsistent scans from 20+ years ago
- **Sibling app to lift from:** `../CropBatch` (mature macOS app, same author)

## Resume

---
*Updated by Claude. Source of truth for project position.*
