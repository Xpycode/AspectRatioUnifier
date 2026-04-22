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
*Add decisions as they are made. Future-you will thank present-you.*
