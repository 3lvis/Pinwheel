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
3. Async images — on-screen host + await image load (readiness signal); note blend modes.
4. Mixed-run text — per-run font/color/decoration in one text node; add strikethrough (underline
   exists).
5. Shadows & borders — emit shadow effect + stroke (incl. dashed); plugin already draws strokes.
6. Blur/materials — low fidelity: translucent fill or crop.
7. Gradients / page dots / custom shapes — low priority; gradient paint when detectable.

## Perf follow-up
The SwiftUI grouping signature is O(n²) on large trees (recomputes each subtree at every level).
Memoize bottom-up to O(n) before heavy consumer screens.

## Sequencing
0) On-screen key-view foundation → 1) lazy (mostly falls out) + List backing-walk →
2) token/font registry → 3) fidelity: async images → mixed text → shadows/borders → blur →
gradients.
