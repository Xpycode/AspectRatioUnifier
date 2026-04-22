# AspectRatioUnifier

A macOS app that analyses a set of images, groups them by aspect ratio, and batch-conforms the outliers to a target ratio/size the user picks. Built for photographers cleaning up inconsistent scans of their own archive.

## Core concept

Most batch-resize tools make you pre-decide the target. This one inverts the flow:

1. Import a set
2. App shows a **histogram of aspect ratios found** ("14× at 3:2, 3× at 4:3, 1× at 16:9")
3. User clicks the winning ratio (or picks a preset like 3:2)
4. App computes the median dimensions of that bucket as the target
5. Outliers get scale-to-fill + center-crop to match
6. Preview shows exactly what will be cropped off before commit

## Tech stack

- Swift 6, SwiftUI
- macOS 15.0+ target
- Core Image for scale/crop pipeline
- App Shell Standard: HSplitView, `FCPToolbarButtonStyle`, `.windowStyle(.hiddenTitleBar)`, `.preferredColorScheme(.dark)`, `Theme` struct
- See `docs/cookbook/00-app-shell.md`

## Code reuse from CropBatch

This app shares ~70% of its foundation with CropBatch (sibling folder at `../CropBatch`). Lift, don't rewrite:

- Import pipeline (drag-drop + `.fileImporter`)
- Image loading, thumbnail generation, preview view
- Resize + center-crop math (Core Image)
- Export pipeline (format picker, naming patterns, `NSSavePanel`)
- Theme struct, toolbar style, App Shell

What's new in this app:
- **Analysis step** — scan dimensions, bucket by aspect ratio (±1% tolerance)
- **Histogram UI** — the target-picker
- **Batch crop preview** — show what gets cut off before committing

## Project conventions

- Branch before implementing: `feature/`, `fix/`, `experiment/`
- Log architectural choices to `docs/decisions.md`
- Update `docs/PROJECT_STATE.md` after significant progress
- Always clean-build (kill running app → `xcodebuild clean` → build → launch)

## Entry points

- `docs/00_base.md` — Directions system overview
- `docs/PROJECT_STATE.md` — current phase, focus, blockers
- `docs/decisions.md` — architectural decisions log
- `docs/sessions/_index.md` — session logs
