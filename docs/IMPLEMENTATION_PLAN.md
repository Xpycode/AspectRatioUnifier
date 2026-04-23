# AspectRatioUnifier — Implementation Plan

**Status:** APPROVED — decisions §1 confirmed 2026-04-23; proceed with Wave 1.
**Scope:** Get from "docs scaffolded, no code" to "first working build that imports images, shows a ratio histogram, and batch-exports to the picked target."

---

## 1. Three decisions to confirm (from PROJECT_STATE open questions)

These gate §4 onwards. Claude's recommendation + reasoning follows each; user confirms or overrides before execution.

### 1.1 Bucketing tolerance — **±1%, user-adjustable in Preferences**

3:2 = 1.5, 5:3 = 1.667 → gap of 11%. ±1% is wide enough to absorb scanner-bed skew + film curvature (typically 0.3–0.8% drift on 35mm scans) but narrow enough that no two named ratios collide. Exposed as a setting in Preferences (Wave 6) so advanced users can go tighter if their scans are cleaner.

### 1.2 Tie-break when two buckets tie on count — **"closer to a named preset wins"**

Named presets = {1:1, 4:5, 5:4, 4:3, 3:2, 16:9, 16:10, 9:16, 2:3, 3:4}. Tie-break order: (a) closer ratio to any preset; (b) if still tied, higher image count in a ±0.5% sub-bucket (penalise buckets that are actually two ratios borderline-merged); (c) if still tied, smaller ratio value (deterministic, stable).

### 1.3 Upscale policy — **flag + user-deselects**

Items whose source dims are below the target dims get a ⚠ overlay in the preview grid. Click toggles include/exclude. Footer: "14 included (3 with upscale) / 3 excluded." Default state is *included* — don't silently drop items; show the cost and let the user decide. Quick action: "Deselect all upscales" / "Reselect all."

---

## 2. CropBatch reuse map (verified via ripgrep symbol scan)

Foundation: `../CropBatch` (mature sibling, same author, same toolchain).

### 2.1 Lift as-is (no changes expected)

| File | Role |
|------|------|
| `Config.swift` (44 lines) | Constants — trim blur/snap sections, keep thumb-cache + history |
| `Services/Logging.swift` (8 lines) | `CropBatchLogger` → rename to `ARULogger` |
| `Services/ThumbnailCache.swift` (106 lines, `actor`) | Unchanged |
| `Services/UpdateController.swift` (38 lines) | Sparkle — blank feed URL until we have one |
| `Services/ExportCoordinator.swift` (262 lines) | Export flow, overwrite dialog, save-in-place |
| `Services/FileSizeEstimator.swift` | Keep |
| `Services/FolderWatcher.swift` | Keep (optional, powers folder-watch mode) |
| `Models/ImageManager.swift` (223 lines) | Collection + navigation |
| `Models/ImageTransform.swift` (60 lines) | Rotation/flip for optional per-image rotate |
| `Views/DropZoneView.swift` (76 lines) | Import UI |
| `Views/FCPToolbarButtonStyle.swift` (31 lines) | Button style |
| `Views/ImageGridView.swift` (213 lines) | Thumbnail grid (reused in preview pane) |
| `Views/ThumbnailStripView.swift` (562 lines) | Thumb strip (bottom of preview) |
| `Views/ZoomPicker.swift` | Zoom level control |

### 2.2 Lift with surgery

| File | Surgery |
|------|---------|
| `CropBatchApp.swift` (371 lines) | Delete Crop menu (line 216+) and most of Image menu — keep File + Edit + View + App. Reroute to new `ARUApp`. |
| `ContentView.swift` (328 lines) | Replace `SidebarTab` enum with ARU's two-tab model (Analyze, Export). Replace sidebar + detail panel with histogram-driven flow. |
| `Models/AppState.swift` (749 lines) | **Most invasive.** Remove `CropManager`, `BlurManager`, `WatermarkSettings`, `SnapPointsManager`, `PresetManager` composed members. Keep `ImageManager`, `ExportSettings`. Trim ~400 lines. |
| `Models/ExportSettings.swift` (520 lines) | Keep `ExportFormat`, `ResizeMode`, `ResizeSettings`, `RenameSettings`, `ExportSettings`, `OverwriteChoice`, `ExportPreset`, `UserExportProfile`, `ExportSettingsCodable`. Delete `GridSettings`. |
| `Views/ExportSettingsView.swift` (1664 lines) | Strip watermark section (line 819–1477, ~660 lines). Keep format/quality/resize/rename/output-preview. |
| `Views/BatchReviewView.swift` (332 lines) | Basis for our new preview — add the "what gets cropped" overlay + upscale-warning badge. |
| `Services/ImageCropService.swift` (1025 lines) | **Keep only the scale+center-crop core** (lines 1–274 roughly). Strip blur pipeline (275–412), watermark overlay (413+). Target ~300 lines. |

### 2.3 Strip entirely (do not copy)

`Models/CropManager.swift`, `Models/CropPreset.swift`, `Models/CropSettings.swift`, `Models/BlurManager.swift`, `Models/BlurRegion.swift`, `Models/WatermarkSettings.swift`, `Models/SnapPointsManager.swift`, `Services/RectangleDetector.swift`, `Services/UIDetector.swift`, `Services/PresetManager.swift`, `Views/CropEditorView.swift`, `Views/BlurEditorView.swift`, `Views/CropSettingsView.swift`, `Views/PresetPickerView.swift`, `Views/FolderWatchView.swift` (for v1), `Views/BatchReviewView.swift`'s grid-split pieces.

`Models/NormalizedGeometry.swift` — evaluate during wave 3; may keep as a coordinate helper.

---

## 3. New modules (what this app adds)

### 3.1 `Models/AspectRatioBucket.swift` (~80 lines, new)

```swift
struct AspectRatioBucket: Identifiable, Hashable {
    let id: UUID
    let ratio: Double              // e.g. 1.5 for 3:2
    let label: String              // "3:2", "4:3", or "1.67:1" if no named match
    let items: [BucketItem]        // indices into imageManager.images
    let medianSize: CGSize         // median (w, h) of items in pixels
    let isNamedPreset: Bool
}

struct BucketItem: Hashable {
    let imageID: ImageItem.ID
    let pixelSize: CGSize          // read via CGImageSource metadata only
    let ratio: Double
    var isExcluded: Bool = false   // user can opt-out upscales
    var requiresUpscale: Bool { /* computed vs current target */ }
}
```

### 3.2 `Services/RatioAnalyzer.swift` (~150 lines, new)

- `analyze(urls: [URL]) async -> [AspectRatioBucket]`
- Reads pixel dims via `CGImageSourceCopyPropertiesAtIndex` with `kCGImagePropertyPixelWidth`/`Height` — **no image decode**, ~10ms per file on SSD
- Buckets by ±1% tolerance (§1.1), picks median size per bucket
- Named-preset snap: if a bucket's centre ratio is within 0.2% of {1:1, 4:5, 5:4, 4:3, 3:2, 16:9, 16:10, 9:16, 2:3, 3:4}, label it as such
- Uses `withTaskGroup` bounded fan-out (cookbook §35) — `maxConcurrent = ProcessInfo.activeProcessorCount`

### 3.3 `Views/HistogramView.swift` (~120 lines, new)

- `HStack` of clickable bars, one per bucket, height proportional to count
- No Swift Charts dependency — single-purpose, Rectangle-based; simpler deps, more control
- Selected bucket gets Theme accent border; others dimmed
- Shows count label ("14×") + ratio label ("3:2") + median-size sub-label
- "Pick this as target" button under selected bar

### 3.4 `Views/CropPreviewBadge.swift` (~60 lines, new)

- Small overlay on grid/strip thumbs: shows the ratio-normalised crop rectangle as a dashed overlay
- `⚠` badge when the source must be upscaled to hit target dims
- Click handler toggles `BucketItem.isExcluded`; excluded items render at 40% opacity with a dashed red border
- Footer strip: "N included (M with upscale) / K excluded" + "Deselect all upscales" / "Reselect all" actions

### 3.5 `Services/RatioTargetResolver.swift` (~60 lines, new)

- Given a picked `AspectRatioBucket`, returns `targetSize: CGSize` + `scaleMode: .fill` (always fill, center-crop the overhang)
- Auto mode (§1 algorithm A): picks the highest-count bucket automatically; one-click fast path from the toolbar

### 3.6 Modifications to kept files

- `AppState.swift` — add `analyzer`, `buckets: [AspectRatioBucket]`, `selectedBucket`, `targetSize`
- `ContentView.swift` — two-tab flow: **Analyze** (dropzone → histogram → target pick) → **Preview+Export** (grid with badges → batch crop-resize → export)

---

## 4. Wave-ordered execution plan

Each wave is a git branch, ends in a working build, and can be checkpointed. Abort if any wave doesn't compile.

### Wave 1 — Clone-rename (branch `feature/clone-rename`)

Follows cookbook §34 verbatim. ~20 min.

```bash
SRC=/Users/sim/XcodeProjects/1-macOS/CropBatch/01_Project
DST=/Users/sim/XcodeProjects/1-macOS/AspectRatioUnifier/01_Project
mkdir -p "$DST"
cp -R "$SRC/CropBatch"            "$DST/AspectRatioUnifier"
cp -R "$SRC/CropBatch.xcodeproj"  "$DST/AspectRatioUnifier.xcodeproj"
rm -rf "$DST/AspectRatioUnifier.xcodeproj/xcuserdata"
rm -rf "$DST/AspectRatioUnifier.xcodeproj/project.xcworkspace/xcuserdata"
mv "$DST/AspectRatioUnifier/CropBatchApp.swift"     "$DST/AspectRatioUnifier/AspectRatioUnifierApp.swift"
mv "$DST/AspectRatioUnifier/CropBatch.entitlements" "$DST/AspectRatioUnifier/AspectRatioUnifier.entitlements"

PBX="$DST/AspectRatioUnifier.xcodeproj/project.pbxproj"
sed -i '' 's/CropBatch/AspectRatioUnifier/g' "$PBX"
# TODO: confirm source bundle id with grep before this sed
sed -i '' 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = 0.1.0;/g' "$PBX"
sed -i '' 's/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = 1;/g' "$PBX"
sed -i '' 's/INFOPLIST_KEY_CFBundleDisplayName = CropBatch;/INFOPLIST_KEY_CFBundleDisplayName = "Aspect Ratio Unifier";/g' "$PBX"
find "$DST/AspectRatioUnifier" -name "*.swift" -exec sed -i '' 's/CropBatch/AspectRatioUnifier/g' {} \;

# Blank Sparkle feed URL until we host one
grep -rn "feed.*\.xml\|appcast" "$DST/AspectRatioUnifier" --include="*.swift"
```

**Gate:** `xcodebuild -scheme AspectRatioUnifier -project AspectRatioUnifier.xcodeproj clean build` prints `** BUILD SUCCEEDED **` with zero errors. App launches with CropBatch's full UI, just renamed.

**Commit:** `feat: clone CropBatch → AspectRatioUnifier (no functional changes)`

### Wave 2 — Strip non-reused modules (branch `feature/strip-unused`)

Delete files listed in §2.3. Delete references in `project.pbxproj` (Xcode auto-heals if we `git rm` the files and re-open the project, but safer to strip pbxproj references too).

Fix compile errors from dangling references in kept files:
- `AppState.swift` — remove composed `CropManager`/`BlurManager`/etc., remove methods that touched them
- `ContentView.swift` — strip sidebar tabs that pointed at crop/blur editors
- `CropBatchApp.swift` — strip Image + Crop menus

**Gate:** Build succeeds. App launches. Import works. Export dialog opens (nothing to export yet — dropzone + grid only).

**Commit:** `refactor: strip crop/blur/watermark/preset modules inherited from CropBatch`

### Wave 3 — Aspect-ratio analysis (branch `feature/ratio-analysis`)

Add `Models/AspectRatioBucket.swift` + `Services/RatioAnalyzer.swift`. No UI yet — verify via unit test or a temporary `print()` on import.

**Gate:** Drop 20 mixed-ratio images → log shows bucket histogram. `RatioAnalyzer` returns in <500ms for 200 images.

**Commit:** `feat: aspect-ratio analysis pipeline`

### Wave 4 — Histogram picker UI (branch `feature/histogram-ui`)

Add `Views/HistogramView.swift` + `Services/RatioTargetResolver.swift`. Wire into `ContentView` as the new "Analyze" tab.

**Gate:** Drop images → see histogram → click bar → see target ratio + median size in a sidebar readout. No export yet.

**Commit:** `feat: ratio histogram picker + target resolver`

### Wave 5 — Batch crop-resize preview + export (branch `feature/batch-preview`)

- Adapt `BatchReviewView` → `PreviewGridView`
- Add `CropPreviewBadge` — dashed overlay showing crop
- Wire through the existing `ExportCoordinator` with `ResizeMode.fill` + centre-crop, target = picked bucket median
- Upscale warning badge (§1.3)

**Gate:** Drop 20 mixed-ratio images → pick 3:2 → preview shows crop overlays → export → 20 files in picked folder, all 3:2 at median-3:2 dims, with the "3 upscaled" ones having been upscaled.

**Commit:** `feat: batch crop-resize preview and export`

### Wave 6 — Preferences + polish + app shell audit (branch `feature/polish`)

- **Preferences pane** with the bucketing-tolerance setting (§1.1) — numeric field with %, default 1.0
- Run `/shell-check` against App Shell Standard (cookbook §00)
- Update `Theme` colours if needed (ARU vs CropBatch brand differentiation — optional, can stay identical)
- README.md, first DMG, Sparkle feed URL when ready

---

## 5. Decision log additions (to append to `decisions.md` once §1 is confirmed)

Appended to `decisions.md` on 2026-04-23:
- Bucketing tolerance ±1%, user-adjustable in Preferences
- Tie-break: named-preset closeness → ±0.5% sub-bucket count → deterministic ratio order
- Upscale policy: flag + user-deselect (default include, click to exclude); never silent, never refuse

---

## 6. Out of scope for v1

- Folder-watch mode (CropBatch has it; punt)
- Per-image rotate before analysis (assumes EXIF orientation already applied on import — CropBatch's behaviour)
- Custom target ratio that isn't a detected bucket (v2 — "I want 4:3 even though there are none in the set")
- Multi-bucket export (all 3:2 to A/, all 4:3 to B/)
- iOS/iPad port

---

## 7. Risks

| Risk | Mitigation |
|------|------------|
| AppState surgery breaks the still-published bindings | Wave 2 gate = build + launch; abort branch if broken, revert |
| CropBatch's Sparkle feed URL ships in clone and serves CropBatch updates to ARU users | Grep for `appcast\|feed` in Wave 1; blank before first commit |
| ExportSettingsView watermark strip leaves dangling `WatermarkSettings` type references | Keep watermark section compiled but hide it via `#if false` in Wave 2; delete properly in Wave 6 |
| `ImageCropService` scale-crop core has blur-pipeline branches inline | Extract clean scale-crop function first, strip blur second |

---

*Next step after §1 confirmed: execute Wave 1.*
