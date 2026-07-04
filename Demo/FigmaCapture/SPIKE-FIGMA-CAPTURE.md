# SwiftUI → Figma capture

Serializes a Pinwheel screen into the **same JSON** fonno's Figma plugin imports
(`fonno/frontend/tools/figma-capture/plugin/code.ts`), so that plugin — which builds Figma
component masters/instances, binds token variables, and creates text styles — is reused
unchanged. Source stays the design source of truth; Figma becomes the playground.

## What it does

Capture is a side effect of *rendering* — a component wrapped in `FigmaCaptureHost` reads its
own `PinCaptureKey` descriptors, resolves each anchor to a frame, writes fonno's IR to
`Documents/figma-capture.json`, and pushes it to the local capture serve, on appear. No special
launch mode: just render it, via the **Screens** section of the catalog or an isolated preview
deep-link.

```
# render (with the serve running) → the app pushes its IR to the serve
xcrun simctl launch <booted> com.nordser.pinwheel -PinwheelPreview swiftui-figma-capture
# then click "Import layers" in the plugin — always the latest render
```

The push is best-effort over `http://localhost:8787` (loopback reaches the Mac from the sim; the
Demo's `Info.plist` allows it via `NSAllowsLocalNetworking`). If the serve started *after* the
render, `npm run figma:pull` copies the sim's file across as a fallback.

It can't run at build time — the frames come from a real SwiftUI layout pass, so it needs a
booted simulator — but it needs no manual navigation: `Scripts/preview-all.sh` already sweeps
every catalog id via `-PinwheelPreview`, so one run emits every component's capture JSON.

## Authoring: the `@Pinnable` macro (no boilerplate)

Components don't hand-write capture wiring. `@Pinnable` (a SwiftSync-style macro in the
`PinwheelMacros` package) generates the style descriptor from annotations:

```swift
@Pinnable(cornerRadius: .spacingM, centersText: true)
public struct PinButton: View {
    @PinText       private let title: String?
    @PinFill @PinColor private var style: Style = .primary
    @PinTypography private var typography: PinTextStyle = .subtitleSemibold
    var body: some View { … .pinCaptured(pinnedStyle) }   // one line
}
```

- The component **name is the type's own name** (`PinButton`) — compiler-unique, so two
  components can't silently collide the way a free-text string could.
- The `Style → token` and `TextColor → token` name maps live **once** on the token enums
  (`PinFillToken`/`PinTextColorToken`), reused across components, not copied per component.
- Adding a component is annotate-and-go; the switch maps and argument assembly are synthesized.

## What's proven (round-trip verified via the Figma REST API)

- The IR is source-agnostic: SwiftUI emits the identical tree the web DOM walker does;
  `serve.mjs` and the shared plugin need no SwiftUI-specific changes.
- Geometry is real, not guessed — a `Spacer` pushes the buttons down; those frames come from
  an actual hosted layout pass.
- Components rebuild as real Figma **masters + instances**; a repeated component keeps its own
  text and fill per instance.
- **Fills** bind to token **variables** by name (`actionText`) and **fonts** bind to Figma
  **text styles** (`type/title`, `type/body`) on a single "Import layers" click.
- Button labels center in their pill; plain labels stay leading.
- **Non-structured views rasterize** — native controls (segmented, switch), SF Symbols, and
  images that have no token descriptor are captured as PNG image nodes and rebuilt as Figma
  image fills. `CapturedImageView` snapshots the *real on-screen window* and crops to the view's
  frame (ImageRenderer draws a placeholder for UIKit-backed controls; a hosted off-screen copy
  renders blank). Caveat: the view must be visible on screen when captured.
- **Widths match the device**: the plugin measures its own render and adds letter-spacing to
  hit the captured iOS text width, compensating for SF Pro Rounded's optical-spacing difference
  (labels + "Cancel" exact; "Pay now" within a sub-pixel).
- **Below-the-fold content captures in full**: a `ScrollView` of eager content lays out entirely
  in one pass, so every anchor carries its real content-space position; the frame is sized to the
  whole content, not the visible viewport, and the screen imports "unrolled" as one tall Figma
  frame. Verified with a 24-row checkout (1114pt tall) — rows and buttons past the 778pt fold land
  at their true positions.
- **The imported frame is named** by the captured screen (`FigmaCaptureHost(name:)` → root node
  `name`), so it reads "Checkout" in Figma, not "screen".
- **The whole catalog sweeps into a plugin list** (first slice of the north star): `Scripts/capture-all.sh`
  renders every catalog item in isolation (`-PinwheelCapture <id>`, hosting `PinwheelItem.swiftUIView()`)
  and pushes each capture — keyed by id, with title/section/tags — to the serve's `POST /catalog`. The
  serve accumulates `catalog-<id>.json` files; `GET /manifest.json` lists them and the plugin's "Load
  catalog" button imports any one, no relaunch per component. Ids come from a `-PinwheelManifest` dump
  of the registry, not source grepping. `@Pinnable` components carry full node trees (Button → 12
  nodes, Label → 5); token/UIKit-only examples appear in the list but capture little until annotated.

## North star — a deployed design-catalog service

The running app *is* the design, published as a catalog a designer browses in Figma — no Xcode, no
simulator in their hands. Generation is render-bound and consumption is static JSON, so the two
decouple cleanly:

- **Generate** (needs a render → a sim, so **CI post-merge**, not a pre-merge gate): one sweep runs
  `Scripts/preview-all.sh` over every catalog id and emits a **manifest** — `{ sections, items:
  [{id, title, section, tags, json}] }` — mirroring the Swift catalog (`DemoPinwheelSections` / the
  `Catalog` enum).
- **Publish**: POST the bundle to a **deployed ingest service** — `serve.mjs` with its
  `POST /capture.json` is the prototype; promoting it is a base-URL swap plus auth, the plugin code
  is unchanged. Two decisions the design must account for: **ingest auth** (only CI publishes, via a
  token; reads open or gated to designers) and **versioning** (key each bundle by git SHA/release, so
  designers pull a stable version and you get design *diffs across releases* nearly for free).
- **Consume** (no app, no sim): the plugin fetches the manifest and shows a catalog-style list
  (sections + SwiftUI/UIKit tag chips), importing a picked component, screen, or tag-selected
  **flow** (N `root` frames laid out into a board).

**Cheapest first step: the manifest sweep.** It's useful immediately against the local serve (the
plugin gets a component list, no relaunch per component) and it's the *same* code the deployed
service consumes later — bottom-up, nothing wasted. The rest is real work gated on one infra
decision (where the service lives); parked until then.

## Plan / not yet done

- **Harden `@Pinnable`** — diagnostics: a clear compile error when a required marker is missing
  or a marked property's type doesn't conform to the expected token protocol, instead of a
  confusing downstream failure.
- **Extend annotation** to the rest of the `Pin*` components as screens need them (only
  `PinLabel`/`PinButton` today).
- **Light + dark capture** — RGBA currently resolves against light only; emit both modes so the
  imported design carries both.
- **Vector assets (SVG/PDF)** rasterize like everything else — loses scalability; preserving
  them as Figma vector paths is a real next step.
- **SF Symbols** are pixels today; the better end state maps them to a Figma icon-library
  component via Code Connect (a shared vocabulary, like the color tokens).
- **Link native controls to Apple's iOS UI Kit (opt-in premium tier).** Instead of rasterizing
  a native control, instantiate Apple's official component so it's editable. Graceful: try to
  find the component; fall back to the image if absent. Gated on the designer having the kit
  (in-file, or enabled as a team library — the scalable form) — so parked until a consumer has
  it. The variant mapping is already known:
  - Switch → `Toggle - Switch`, set `State` = On/Off.
  - Segmented → `Segmented control`, set `Segments` (count), `Selected` (index), `Label N` (titles).
  - Plugin matches prop keys by prefix (they carry `#id` suffixes: `State#6152:0`), robust across
    kit versions; `createInstance()` + `setProperties()`.
- **Lazy lists capture structurally by laying out eagerly.** A lazy `List` only lays out visible rows,
  but the data source is finite — so render the same `PinList.Row` values in an eager `VStack` and every
  row resolves its frame and captures its `PinLabel`s as *editable* text, below the fold included. Proven
  on a 30-row list — 60 label nodes, all rows, doc 1100pt tall (`-PinwheelListCapture`). Editable rows,
  no macros, no rasterization.
- **Rows group into frames, native bits and all.** `.pinCapturedContainer(name:)` marks a row a group;
  the host nests every captured node whose frame falls inside it (by geometry, innermost wins), so each
  row rebuilds as one Figma frame holding its labels *and* its native bits — a `Toggle`/chevron captured
  as a rasterized image node. Verified on 18 rows: each a group with its children (title, supporting
  text, toggle/chevron). The grouping and structured labels work below the fold too; only the *rasterized*
  native bit needs the row on screen (the window-crop constraint), so below-fold rows group their labels
  without it. `.pinCapturedContainer` uses `transformAnchorPreference` (not `anchorPreference`, which
  would drop the row's own descendants).
- **Identical rows reuse one component (master + instances).** A row's capture name is its *structure*
  (`Row-subtitle-detail-chevron`, `Row-toggle-subtitle-on`), not its data, so structurally-identical rows
  share a Figma component: the first is the master, the rest are instances the plugin fills with only
  their own text (`applyInstanceContent` overrides the instance's nested text by position, keeping each
  label's inherited style). The payoff: the native bit (chevron/switch) is captured **once** on the master
  and inherited by every instance — so below-the-fold *repeated* rows need no photo of their own, only the
  master must be on screen. Toggle on/off are separate templates (the switch image differs). Verified: 10
  rows → 3 templates (7+2+1).
- **`PinList.Row` self-captures.** The grouping now lives in the component: `PinList.Row.body` applies
  `.pinCapturedContainer(name:)`, so a real `PinList` laid out eagerly captures its rows as grouped,
  editable frames with *no capture code at the call site* — verified with actual `.text` rows (18 groups,
  each its title/subtitle/detail labels, round-tripped through Figma and inspected back). It's a no-op when
  nothing reads the preference, so ordinary rendering is unaffected.
- **Native bits capture via a host-rasterization hook.** The row's chevron/switch have no structured
  description, so the library marks them with `.pinCapturedRasterized(name:)` — a *pure-SwiftUI marker*,
  no window-capture code in the library — and the host photographs each marker's on-screen frame
  (`ScreenCrop`, the anchor offset by the reader's global origin). Verified: real `PinList.Row`s
  round-trip with their labels *and* their `Chevron`/`Switch` images. Off-screen markers can't be
  photographed, so below-the-fold native bits are best-effort — mitigated by a taller capture device
  (iPad portrait fits more) or by reusing one captured bit across identical rows.
- **Scroll-and-stitch is the rasterized fallback** for lazy content that can't lay out eagerly — chiefly
  `UIKitPinTableView` (a real `UITableView`). `ScrollStitch` pages the backing scroll view, window-crops
  each page, and emits one image node per page (each under Figma's 4096px cap). Proven on a 30-row list
  (`-PinwheelTableCapture`). Whole component as an image, not editable rows — use only when eager layout
  isn't possible.
- **Nested auto-layout** — emit `layout` for `HStack`/`VStack` containers; today every node is
  absolute under the root (the IR already supports both, so this degrades gracefully).
- **The "Pay now" sub-pixel** — only if exactness is wanted: have `PinButton` emit its real
  laid-out label width instead of `.size`.
