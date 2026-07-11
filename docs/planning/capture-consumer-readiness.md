# Figma Capture — Consumer-Readiness Plan (agnostic)

Goal: a real SwiftUI-first app adopts the capture pipeline with minimal changes — most
components capture as-is; the consumer supplies their design tokens + fonts and changes
nothing structural.

## Foundation — capture from the on-screen key view (retire the off-screen path)
Today there are two capture paths: an on-screen live host (UIKit controls only paint on a real
window) and an off-screen one that builds + activates its own `UIWindow`. The off-screen
activation is fragile (crashes on hostless/headless test processes) and renders incompletely
(lazy content, async images, controls). Decision: make the **component the key-window root** and
float the catalog chrome as an overlay layer, so capture always reads the real, on-screen tree.
- One capture path, not two; no off-screen window activation.
- Directly unblocks Blocker 1 (lazy realizes on a real sized window) and fidelity (async images
  load, controls paint).
- Test strategy: verify capture through the on-screen sweep / DemoUITests in the hosted Demo app
  (real window + scene); retire off-screen hostless-window unit tests (also removes the runner
  flake if Actions returns). Keep pure-logic unit tests (token matching, signatures, IR shape).
- Cost to weigh: catalog pickers/settings become overlays (layout + hit-testing rework; the FAB
  already lives in a pass-through window, so there's precedent).

## Blocker 1 — Lazy container capture
`List`, `LazyVStack`, `LazyVGrid`, `LazyHStack` are viewport-gated → capture empty *off-screen*.
Measured on the on-screen sweep host (demos in Screens, `.figma`):
- **`LazyVStack` — SOLVED.** 20/20 cards captured (`figma-lazy-cards`). The content-height live host
  makes the outer ScrollView's viewport == content, so every row realizes into the DisplayList.
- **`LazyVGrid` — SOLVED.** 12/12 tiles captured (`figma-lazy-grid`). (Per-tile fill fidelity is a
  follow-up — labels all present; the containment path flattened the tile backgrounds.)
- **`List` — editable capture WORKING (partial for rich rows), via `PinSwiftUIListCapture`.** A SwiftUI
  `List` is a recycled `UICollectionView` (`UpdateCoalescingCollectionView`); each row is its own SwiftUI
  hosting boundary (`ListCollectionViewCell → _UICollectionViewListCellContentView → CellHostingView`).
  Two moves crack it: (1) **force-realize** — size the collection to its `contentSize` so every cell exists
  (14→20 confirmed); (2) **read each cell's own DisplayList** — `CellHostingView` reflects to an empty
  `Mirror`, but its `_base` (a `UIHostingViewBase` with the full `viewGraph`) is reachable via the **ObjC
  runtime** (`class_getInstanceVariable`/`object_getIvar`). So `displayList(of:)` fetches `_base` via Mirror
  *or* the ObjC ivar, and per-cell capture composes the rows into a screen.
  - **Text-dominant rows: full** — proven, a plain-text `List` captures every row as editable text
    (`testListRowsCaptureAsEditableText`, `Row 1…Row 12`).
  - **Rich rows: partial** — `ProductListDemo` (image + title + SALE pill + was/now price + stepper) goes
    from a **blank box** to **structured rows** with the image placeholder + one text fragment each (title
    or stepper). SwiftUI scatters a rich row across several nested hosting views and only some expose a
    readable DisplayList (a `Button`'s label, an inline stepper's text can host in a form that yields
    nothing). Capturing every hosting view didn't recover them — a genuine long-tail internals gap.
  - Wired ahead of the DisplayList path for SwiftUI items (`PinSwiftUIListCapture.document(...) ?? displayList()`);
    returns nil (falls through) for non-`List` screens. The `_base`-via-ObjC change is regression-free for
    the root `_UIHostingView` path (it still finds `_base` via Mirror first).
  - Follow-up: recover the missing rich-row fragments (map SwiftUI's control/image hosting forms) if full
    fidelity on raw-`List` Cart-style rows is needed; today they capture as structured-but-partial.
- **The clean path for consumers: `PinList` with a capture switch (`pinCapturing`).** A raw `List`'s
  rich rows only capture partially; but a consumer list built on `PinList` captures **fully**. `PinList`
  renders a real `List` in production (recycling, native separators) and, under the `pinCapturing`
  environment (set by the capture pipeline in `PinDisplayList.read` and the sweep host), renders the same
  rows in an eager stack the DisplayList reads completely. Same `Row` in both — 1:1 cells. Result
  (`PinListDemo`, 6 rows): **all row text editable + 1 component + 5 instances**, chevron included. So a
  consumer routes lists through `PinList` (a small, non-structural change) and gets editable design +
  component-as-rows + instances-on-repeat, sidestepping the raw-`List` wall entirely.
- **Grouping signature handles images + width jitter.** Repeated-cell componentization keys an image node
  by its **bytes** (identical icons/chevrons group; per-row photos stay distinct — an instance can't
  override an image) and buckets size to ~16pt (content-driven width jitter, e.g. a longer price, doesn't
  split one template; a real 120-vs-240 difference still does).
- Layout-fidelity follow-up: the lazy demos fell to the containment path (`root=frame`, not `screen`),
  so auto-layout/component-grouping is lossier than the reflection path. Investigate matching the
  reflection path for large lazy trees.
- Tall content beyond one screen: scroll-and-stitch the live container as a fallback.

## Blocker 2 — Consumer-supplied token & font registry
Engine value-matched colors/spacing/radius against fixed library enums and hardcoded the font family.
- **Phase 1 — DONE (`PinCaptureTokens`).** A consumer-supplied registry the matchers consult:
  `PinCaptureTokens.current` (defaults to `.pinwheel`) holds color tokens (name + light/dark + a
  `textEligible` flag so a text color doesn't bind a background token), spacing + radius float tokens, and
  a `systemFontFamily`. The color/float matchers (`tokenName`, `spacingName`/`radiusName`/`gapName`) and
  the Figma-variable emitters (`figmaColorTokens`/`figmaFloatTokens`) route through `.current`; captured
  text reads its **actual** font family (custom fonts carry through; the system font falls back to
  `systemFontFamily`). Default preserves current behavior — full suite green. Tests: a custom color binds
  a custom name, a custom spacing binds, a custom font family is emitted, and the default still binds
  Pinwheel tokens.
- **Phase 2 — DONE (text styles).** A consumer's named text styles now match + emit from the registry:
  `PinCaptureTokens.textStyles` (name/family/size/weight); `textStyleName(for:)` matches a rendered font by
  size + weight, `figmaFont.style` and the document's emitted `textStyles` route through `.current`.
  Default preserves the Pinwheel style names (existing typography tests green). Consumer "adapter" is just
  building a `PinCaptureTokens` from their design system — the public init *is* the seam, no extra API.
- **Font availability is the consumer's job (not ours).** Figma renders a family only if it's a Google
  Font, installed on the designer's machine (desktop app), or a shared Org font — and the plugin API can't
  install fonts. The pipeline emits the family name; the consumer makes their brand fonts available in
  Figma. The plugin already **falls back to Inter** (`resolveFont`) when a family isn't loadable, so a
  missing font never breaks the import.
- Multi-brand: swap `PinCaptureTokens.current` per brand before capture.

## Fidelity gaps
3. **Real / async images — DONE.** A raster image (`Image(uiImage:)`, a loaded `AsyncImage`) has
   DisplayList content kind `image`, which was unhandled — `contentKind` returned `.unknown` and the
   photo was dropped entirely (SF Symbols only worked because they're vector `shape` content).
   `contentKind` now maps `image` → `.rasterizable`, so the existing host-layer crop fills it with real
   pixels, same path as a symbol. Red-first (`RasterImageCaptureTests`); verified end-to-end via the
   capturable `ImageGalleryDemo` — three `AsyncImage(url:)` photos capture as 64×64 image nodes with
   pixels + dark variants. Readiness caveat: capture reads after the sweep's fixed 0.5s, so a
   *local/fast* image (bundled, file-URL, cached) is loaded in time; a genuinely slow *remote* fetch
   could still miss the window — a bounded load-await on the live host is the follow-up.
4. Text decoration + mixed runs.
   - **Strikethrough — DONE.** `textKind` reads `.strikethroughStyle` alongside `.underlineStyle`,
     threads it through `FigmaFont.strikethrough`, and the plugin draws `STRIKETHROUGH` (skipping the
     style binding that would wipe it, same as underline). Verified end-to-end: the capturable
     `PricingDemo` (eager `ScrollView`/`VStack`) serializes all four struck "was" prices as
     `strikethrough:true` with their caption style + `secondaryText` token intact. A raw `List`
     still can't (the struck price never enters its partial capture — known List limitation).
   - **Mixed-run text — remaining.** Per-run font/color within one text node: `textKind` reads only
     run 0's attributes, so a `Text("A") + Text("B").bold()` captures as one uniform run.
5. Borders / strokes.
   - **Editable stroke — HARD WALL.** SwiftUI resolves `.stroke(color, lineWidth:)` to a *filled ring
     path* before it reaches the DisplayList: the shape payload is `(Path, AnyResolvedPaint, FillStyle)`
     — a `FillStyle`, never a `StrokeStyle`, so there is **no `lineWidth`** to read (probe-confirmed on
     a `Capsule().stroke(_, lineWidth: 1)`). The width is baked into the ring geometry. So the plugin's
     `node.stroke`/`strokeWeight` (which it already supports) can't be driven from the capture — the
     border can only be *rasterized* (the ring already captures as a `.rasterizable` bitmap leaf). To
     emit an editable stroke we'd have to infer width+radius from the ring's Path geometry (fragile).
   - **Enclosing-rasterizable image dropped.** Even the rasterized border is lost today: the ring image
     *encloses* the stepper's contents, so `containmentTree` makes it the parent Box and `emit`'s
     container branch drops the parent's own image (a `.roundedRect` parent keeps its fill; a
     `.rasterizable` parent doesn't). Fixing that (emit the enclosing image behind its children) would
     render the border as a bitmap, at the cost of turning that frame absolute — low value (non-editable)
     vs regression risk, so deferred.
6. **SALE-pill fill — FIXED.** A `.background(_, in: Capsule())` wrapping a single label (a SALE badge)
   lost its fill whenever the card split into a title-row band + a price band: `emit`'s containment
   vertical-list path ran `flattenLeaves`, which dissolved the fill-bearing pill wrapper down to its bare
   label, so `absoluteRowGroup` rebuilt the row without the capsule — white text, invisible on a light
   card. (Single-row fixtures took a different path and hid it; the multi-row/full-screen case triggers
   it — reproducible at the unit layer, no DemoUITest needed.) `flattenLeaves` now keeps a fill/radius
   box whole and only dissolves transparent groups. Red-first (`SalePillCaptureTests`); verified through
   the real sweep with `figma-plugin/render_ir.py` (renders the captured IR to a PNG for diffing against
   a `-PinwheelPreview` sim screenshot) — the pink pills are back on all three sale rows.
7. Blur/materials — low fidelity: translucent fill or crop.
8. Gradients / page dots / custom shapes — low priority; gradient paint when detectable.

## Complex rows: bespoke 2-D `ForEach` captures via reflection (SHIPPED)
A bespoke 2-D row (`HStack { thumbnail, VStack{title/price}, Spacer, stepper }` in a `ForEach`) now
captures faithfully through the reflection path — no `PinList` required. Two pieces:
1. **The ForEach expander** (`PinVariadicExpander`, `elvis/foreach-fold`) reverse-engineers SwiftUI's
   AttributeGraph: expand the `ForEach` via `_VariadicView.Tree(MultiViewRoot)` (its `body(children:)`
   MUST return the children), then deref each row's `TypedUnaryViewGenerator` through the private
   `AGGraphGetValue` C ABI (dlsym'd, called inside `body`) to recover the real row instance for the
   reflector. Guarded by a cached `isHealthy` self-test canary + graceful containment fallback, so a
   future iOS breaking the private ABI is caught (a red canary test) and never crashes.
2. **Shape leaves close the zip.** The reflection→containment zip gate is exact-count, and a rich row's
   reflected leaves must match the rendered components. The reflector now emits filled/stroked shapes
   (`*ShapeView`, `RoundedRectangle`, …) as leaves but NOT `Image` — containment keeps a shape's fill
   box as a component and drops SF Symbols, so counting `Image` would desync the count the other way.

CartDemo is the bespoke 2-D `ForEach` (restored from PinList) and captures as `root=screen` with the
correct nested `HStack[thumbnail | VStack(title/SALE, now/was) | spacer | stepper]` — no Y-order
scramble. Verified regression-clean: a full-catalog before/after root-tag diff (fix off vs on, clean
builds, light + dark) changed exactly one line — `figma-cart` `frame→screen`; the other 29 demos
byte-identical. `ForEach`-of-*bare-leaf* rows (`ForEach { PinLabel }`) still fall back to containment
(different graph shape; 1-D containment already handles them). Remaining Cart gaps are the stepper
border (§5, hard wall for editable) and the SALE pill fill (§6, on-screen-only drop).

## UI-tier note (environment)
The `DemoUITests` catalog navigation uses a SwiftUI `Menu` section picker that **does not open under UI
automation on iOS 26.5** (the menu never presents; `Tokens`/`Screens` buttons never appear) — the
baseline `b008fec` fails the same tests on 26.5, so it's a runtime issue, not a regression. The suite is
green on iOS 18.3. Harden the picker interaction (or the picker) so the tier runs on the newest runtime
per the durability principle (a test pins a capability, not a snapshot OS).

## Perf follow-up
The SwiftUI grouping signature is O(n²) on large trees (recomputes each subtree at every level).
Memoize bottom-up to O(n) before heavy consumer screens.

## Sequencing
0) On-screen key-view foundation → 1) lazy (mostly falls out) + List backing-walk →
2) token/font registry → 3) fidelity: async images → mixed text → shadows/borders → blur →
gradients.
