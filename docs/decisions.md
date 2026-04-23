# Decisions Log

This file tracks the WHY behind technical and design decisions.

---

## Decisions

### 2026-04-22 — Positioning: specialist, not generalist

**Context:** Need to batch-unify a set of photo scans that drifted into mismatched aspect ratios (user's own 35mm archive, scanned inconsistently 20+ years ago). Many generalist tools exist (Retrobatch, XnConvert, ImageMagick, Photoshop Image Processor, even CropBatch itself) that can crop+resize in bulk.

**Options Considered:**
1. **Fix in CSS only** — `aspect-ratio` + `object-fit: cover` on the gallery page. Zero app needed.
2. **Add a mode to CropBatch** — "Auto-unify" button inside the existing app.
3. **New specialist app** — dedicated tool whose entire UX is built around the analyse-and-propose loop.

**Decision:** Option 3 — new specialist app.

**Rationale:**
- CSS masks but doesn't fix the source files; user needs actual file unification for downloads / reuse / future portfolio work.
- Existing tools all make you pre-decide the target size. None analyse the set first and propose one.
- A CropBatch mode would dilute CropBatch's focus (manual visual cropping) with a fundamentally different flow (automatic batch conforming).
- Specialist one-trick apps have precedent on macOS (ImageOptim, PNGGauntlet, Unshake, Squash).

**Consequences:**
- Separate Xcode project, bundle id, DMG, update feed.
- Must still justify its existence against CropBatch by keeping the UX ruthlessly focused on the analysis-and-propose flow — no feature creep into manual editing.

---

### 2026-04-22 — Target-proposal algorithm: histogram picker, with auto-mode fast path

**Context:** The defining UX question — when the app analyses a set of images, how does it propose the target ratio/size? This decision shapes the whole product.

**Options Considered:**
1. **A — Mode + median:** Auto-detect the most common aspect ratio, use the median size of that bucket. Outliers get cropped. Zero clicks.
2. **B — Histogram picker:** Show a histogram of ratios found ("14× at 3:2, 3× at 4:3, 1× at 16:9"); user picks the bucket; app computes median size of that bucket.
3. **C — Ratio presets:** Offer 3:2 / 4:3 / 1:1 / 16:9 / 5:4 buttons; ignore what's in the set.
4. **D — Lock to one image:** Drag a reference image to a "target" slot; everything conforms to it.

**Decision:** B as primary UX, A as a one-click "Auto" fast path.

**Rationale:**
- B respects that the user — a photographer looking at their own archive — knows which ratio is the vision and which is the scanning artifact. The app handles arithmetic; the user owns taste.
- A as a fast path covers the "I just want this done, don't make me think" mood — especially valuable for this user's 35mm archive, where the answer is overwhelmingly 3:2.
- C is too opinionated — it ignores what's actually in the set.
- D is visually intuitive but fragile for sets with several plausible references.

**Consequences:**
- UI needs: (a) a histogram view as the central widget, (b) a prominent "Auto" button that skips straight to mode+median.
- Bucketing needs a tolerance (±1% initially) so 1.498 and 1.502 don't become separate 3:2 buckets.
- Tie-breaking rule needed when two buckets are equally populated — tentatively: pick whichever bucket's median size is closer to the overall set's median size.

---

### 2026-04-22 — Code reuse strategy: lift from CropBatch

**Context:** CropBatch (sibling folder `../CropBatch`) is a mature macOS app by the same author with overlapping infrastructure: import pipeline, preview, resize+crop math, export, App Shell, Theme. Building AspectRatioUnifier from scratch would duplicate all of it.

**Options Considered:**
1. Start from blank Xcode project, build everything from zero.
2. Clone CropBatch's Xcode project and strip/rename (per `docs/cookbook/34-xcodeproj-clone-rename.md`).
3. Extract CropBatch's reusable layers into a shared Swift package that both apps depend on.

**Decision:** Option 2 — clone-rename CropBatch's project.

**Rationale:**
- Option 1 wastes weeks rebuilding infrastructure that already works.
- Option 3 is architecturally cleaner but a large upfront investment; better done *after* this app ships and the shared surface is proven.
- Option 2 gets to a working shell in under an hour; the new work lives in a single new module (analysis + histogram).

**Consequences:**
- Carry-over debt: any CropBatch quirks come along for the ride. Mitigate by stripping all non-essential views early (crop editor, grid split, blur, watermark, snap-to-edge).
- Updates to the shared code won't flow between apps — each app evolves its own copy until Option 3 is revisited.
- Bundle id, scheme, target, display name, icon, and appcast URL all need renaming (follow the cookbook recipe).

---

### 2026-04-23 — Bucketing tolerance: ±1%, user-adjustable

**Context:** Ratios 1.498 and 1.502 must bucket together as 3:2. Tolerance too tight fragments a single-ratio archive into near-duplicate buckets; too loose merges distinct named ratios.

**Decision:** ±1% default, exposed as a Preferences setting (advanced users can go tighter).

**Rationale:**
- 35mm scanner-bed skew + film curvature typically produces 0.3–0.8% ratio drift — ±1% absorbs it.
- Nearest named-ratio neighbours are ~11% apart (3:2 = 1.500 vs 5:3 = 1.667), so ±1% has no collision risk.
- ±0.5% would fragment a uniformly-3:2 archive; ±2%+ risks merging 3:2 and 5:3 under skew.
- Making it a setting defers the "what if my scanner is worse?" argument until someone actually has that scanner.

**Consequences:**
- `Config.swift` gets `ratioTolerance: Double = 0.01`.
- Preferences pane needed (Wave 6) — a numeric field with %.
- `RatioAnalyzer` reads the tolerance from config at analyse time, not at bucket-creation time, so re-analyses pick up the new value.

---

### 2026-04-23 — Tie-break rule: named-preset closeness

**Context:** When two buckets have equal image counts, which wins the "suggested target" spot in the histogram's default selection?

**Options Considered:**
1. **Closer to overall median size wins** (earlier tentative idea).
2. **Closer to a named preset** (1:1, 4:5, 5:4, 4:3, 3:2, 16:9, 16:10, 9:16, 2:3, 3:4) wins.
3. **Deterministic ratio order** (smaller ratio value first).

**Decision:** 2 primary, 3 as final fallback. Secondary tie-break: higher count in a ±0.5% sub-bucket (penalises buckets that are two borderline ratios merged by tolerance).

**Rationale:**
- Size is orthogonal to ratio; option 1 makes no sense — two buckets can tie on count with wildly different absolute pixel dimensions but identical ratios.
- Named presets correspond to real-world intent. If two buckets tie and one matches 3:2 exactly while the other sits at 1.48, the user almost certainly wants 3:2.
- The sub-bucket check catches cases where a ±1% merge has lumped "almost 3:2" and "actually 1.48" together — if they split under ±0.5% and one side is clearly denser, prefer the denser side.

**Consequences:**
- `AspectRatioBucket` carries an `isNamedPreset` flag and a `distanceToNearestPreset` value for sorting.
- Deterministic order matters — UI must not rearrange bucket order between analyses for the same set.

---

### 2026-04-23 — Upscale policy: flag + user-deselect, never silent

**Context:** The picked target's median size may exceed some source images' dimensions. Scale-to-fill then means upscaling, which degrades.

**Options Considered:**
1. Refuse — force user to pick a smaller target.
2. Allow silently — just upscale.
3. Allow with warning badge + count footer.
4. **Flag undersized items + let user deselect them** — default is "include everything," but the ⚠ badge tells the user exactly which items would be upscaled, and one click removes them from the batch.

**Decision:** 4. Undersized items get a ⚠ overlay in the preview grid. Click toggles exclude/include. Footer shows "14 included (3 with upscale) / 3 excluded." Export skips the excluded set.

**Rationale:**
- Photographers know their archive. Don't patronise (option 1) or hide the downside (option 2).
- Option 3 (just a warning) makes the user feel watched but gives no action — adding deselection closes the loop.
- Default-include rather than default-exclude because a 10% upscale on a 4000×2667 scan is often fine; the user should have to actively decide to drop an item, not actively decide to keep it.

**Consequences:**
- `BucketItem` needs an `isExcluded: Bool` state, toggled from the preview.
- Export coordinator filters on `!isExcluded`.
- UI: dashed red border on the ⚠ badge when excluded; solid amber when included-but-upscale.
- "Select all / deselect all upscales" quick-action in the footer.

---
*Add decisions as they are made. Future-you will thank present-you.*
