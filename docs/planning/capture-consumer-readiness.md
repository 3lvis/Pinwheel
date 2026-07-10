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
- **`List` — editable capture BLOCKED (investigated, `SectionedListDemo`).** A SwiftUI `List` is a
  recycled `UICollectionView` (`UpdateCoalescingCollectionView`). Force-realizing *works* — sizing the
  collection to its `contentSize` realizes every cell (confirmed 14→20). But each row is its own opaque
  SwiftUI hosting boundary (`ListCollectionViewCell → _UICollectionViewListCellContentView →
  CellHostingView`), and none of the editable routes reach it: (1) the root host's DisplayList excludes
  the cells (separate graphs) → captures flat; (2) `CellHostingView` reflects to an **empty Mirror** (no
  `_base`/`viewGraph`), so the per-cell DisplayList extraction that works on the root can't run; (3) cell
  accessibility labels are **empty** (computed lazily). Only per-cell **pixel crops** remain — non-editable
  rows, barely better than the flat image. So editable `List` capture isn't achievable with the current
  DisplayList technique. Options: (a) accept `List` screens capture flat (a documented limitation, like the
  old UIKit-`List` case); (b) per-cell image crops (non-editable but per-row, individually replaceable);
  (c) future non-Mirror extraction into `CellHostingView`'s graph via the ObjC runtime — fragile and
  iOS-version-specific. Recommendation: (a) for now — `List`'s value to the consumer is its *features*
  (sections/swipe/edit), and those screens (Cart, Favorites) can capture flat until (b)/(c) is justified;
  the editable wins are the lazy stacks/grids, which already work.
- Layout-fidelity follow-up: the lazy demos fell to the containment path (`root=frame`, not `screen`),
  so auto-layout/component-grouping is lossier than the reflection path. Investigate matching the
  reflection path for large lazy trees.
- Tall content beyond one screen: scroll-and-stitch the live container as a fallback.

## Blocker 2 — Consumer-supplied token & font registry
Engine value-matches colors/spacing/radius against fixed library enums and hardcodes the font
family → a consumer's tokens/fonts don't bind; text imports under the wrong family.
- A capture-time registry the consumer supplies: named color tokens (light/dark), float tokens
  (spacing/radius), text styles (family, size, weight, line-height). Multiple theme variants,
  selectable per capture. Built-ins become the default registry.
- Refactor value-matchers (tokenName / spacingName / radiusName / text-style matching) to consult
  the registry.
- Read the ACTUAL rendered font family instead of hardcoding it; emit it; bind a consumer text
  style when matched.
- Emit the registry as Figma variables/text styles (mechanism exists; feed consumer tokens).
- Consumer side: a thin adapter mapping their tokens in + uploading their fonts to the Figma file.
- Tests: a custom registry binds a custom color/spacing/text-style; the actual family is emitted.

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
