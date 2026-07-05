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
xcrun simctl launch <booted> com.nordser.pinwheel -PinwheelPreview swiftui-tableview
# then click "Import layers" in the plugin — always the latest render
```

The push is best-effort over `http://localhost:8787` (loopback reaches the Mac from the sim; the
Demo's `Info.plist` allows it via `NSAllowsLocalNetworking`). If the serve started *after* the
render, `npm run figma:pull` copies the sim's file across as a fallback.

It can't run at build time — the frames come from a real SwiftUI layout pass, so it needs a
booted simulator — but it needs no manual navigation: `Scripts/sweep.sh --preview` already sweeps
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
  frame. The eager `PinList` capture rides this: a list longer than the viewport still lands every
  row at its true content-space position.
- **The imported frame is named** by the captured screen (`FigmaCaptureHost(name:)` → root node
  `name`), so it reads e.g. "TableView" in Figma, not "screen".
- **The whole catalog sweeps into a plugin list** (first slice of the north star): `Scripts/sweep.sh --capture`
  renders every catalog item in isolation (`-PinwheelCapture <id>`, hosting `PinwheelItem.swiftUIView()`)
  and pushes each capture — keyed by id, with title/section/tags — to the serve's `POST /catalog`. The
  serve accumulates `catalog-<id>.json` files; `GET /manifest.json` lists them and the plugin's "Load
  catalog" button imports any one, no relaunch per component. Ids come from a `-PinwheelManifest` dump
  of the registry, not source grepping. `@Pinnable` components carry full node trees (Button → 12
  nodes, Label → 5); token/UIKit-only examples appear in the list but capture little until annotated.
- **`PinList` captures itself by laying out eagerly.** A lazy `List` only lays out visible rows, but the
  data source is finite — so under the `pinCapturing` environment (set by the capture host) `PinList`
  swaps its `List` for an eager `VStack`, and every row resolves its frame and captures its `PinLabel`s as
  *editable* text, below the fold included. It's the **real** `PinList` demo (the `TableView` catalog item,
  `swiftui-tableview`) that captures — no separate screen. No macros, no rasterization for the text.
- **`PinList.Row` self-captures, grouped.** `PinList.Row.body` applies `.pinCapturedContainer(name:)`
  (via `transformAnchorPreference`, which appends rather than replacing the row's own labels), so each row
  captures as one grouped Figma frame with *no capture code at the call site*. A no-op when nothing reads
  the preference, so ordinary rendering is unaffected.
- **Native bits capture via a host-rasterization hook.** The row's chevron/switch have no structured
  description, so the library marks them with `.pinCapturedRasterized(name:)` — a *pure-SwiftUI marker*,
  no window-capture in the library — and the host photographs each marker's on-screen frame (`ScreenCrop`).
  Real `PinList.Row`s round-trip with labels *and* `Chevron`/`Switch` images. Off-screen markers can't be
  photographed, so unique below-fold native bits are best-effort (mitigated by a taller capture device).
- **Identical rows reuse one component (master + instances).** A row's capture name is its *structure*
  (`Row-subtitle-detail-chevron`), not its data, so structurally-identical rows share a Figma component:
  the first is the master, the rest instances the plugin fills with only their own text
  (`applyInstanceContent` overrides nested text by position, keeping each label's inherited style). The
  native bit is captured **once** on the master and inherited — so a repeated below-fold row needs no photo
  of its own. Toggle on/off are separate templates. A component's nested `component`-tagged children build
  as plain frames (Figma forbids a component inside a component). Verified via inspect: 10 rows → 3 masters
  + 7 instances, each its own text.
- **Scroll-and-stitch is the rasterized fallback** for lazy content that can't lay out eagerly — chiefly
  the real `UIKitPinTableView` demo (`uikit-tableview`, a genuine recycling `UITableView`). When a captured
  view emits no structured descriptors, the host finds the overflowing scroll view and `ScrollStitch` pages
  it, window-cropping each page into one image node (each under Figma's 4096px cap). Whole component as an
  image, not editable rows — the honest fallback for what eager layout can't reach.
- **Light + dark cross the bridge as variable modes.** Each color token is resolved in both appearances
  (`RGBA(color, style:)`) and the plugin gives the token collection a **Light** and **Dark** mode, binding
  each color variable's two values. Fills bind to the variable, so toggling the Figma mode reskins the whole
  design. Verified: `primaryText` #021622 → #ffffff, `primaryBackground` #ffffff → #1c2024, accent unchanged.
  A second variable mode needs a paid Figma plan; it degrades to light-only otherwise. For testing without
  that, the plugin's **Dark version** toggle paints the captured dark values directly (no binding).
- **Dark native bits come from the simulator's appearance**, not an in-app flip. The old two-pass
  (`overrideUserInterfaceStyle = .dark` on the window, re-crop) was unreliable — SwiftUI's `WindowGroup`
  resets the override, so the dark crop came back light. Instead, set the sim dark
  (`xcrun simctl ui <device> appearance dark`) and the app renders dark natively; the crop then captures a
  real dark control (verified: a full dark switch). So a dark import is: **sim dark** (dark native bits) +
  the plugin's **Dark toggle** (dark colours). Getting *both* appearances into one JSON so the toggle
  switches the images too would be a two-run merge (capture in a light sim and a dark sim, combine) — not
  built; single-appearance per capture today.
- **Stack cross-axis alignment is captured** — a row centers its content (matching a SwiftUI `HStack`), a
  label `VStack` leads; `PinCaptureLayout.alignment` carries it, so an imported toggle row isn't top-aligned.

## North star — a deployed design-catalog service

The running app *is* the design, published as a catalog a designer browses in Figma — no Xcode, no
simulator in their hands. Generation is render-bound and consumption is static JSON, so the two
decouple cleanly:

- **Generate** (needs a render → a sim, so **CI post-merge**, not a pre-merge gate): one sweep runs
  `Scripts/sweep.sh --capture` over every catalog id and emits a **manifest** — `{ sections, items:
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

## What's left (ranked)

The core round-trip and the lazy-list problem are covered every way we could find. What remains:

### The one real fidelity hole

- **Auto-layout — carried by real components, inference remaining.** A container carries a
  `PinCaptureLayout` (axis, spacing, padding); the host emits `layout` and the plugin builds a *hugging*
  Figma auto-layout frame, so the imported design reflows instead of being a fixed snapshot. `PinList.Row`
  emits it for real — its label `VStack` is a nested column container inside the row `HStack` with
  space-between for the trailing accessory. What's left is inferring axis/spacing geometrically where a
  component doesn't declare it, so annotation isn't required everywhere.

### Quick verifications (should work, untested)

- **UIKit table (`UIKitPinTableView`)** — scroll-stitch is scroll-view-agnostic, so it should capture it, but
  only tested on a SwiftUI `List`. Confirm.
- **Grids (`LazyVGrid`)** — lists are done exhaustively; a grid is a different layout, untested.

### Parked projects (need a product decision, then real build — not spikes)

- **Deployed catalog service** — see the North star section above (CI post-merge → hosted ingest → plugin pulls).
- **Flow import** — tag-select several screens, import as one laid-out Figma board.
- **Apple UI Kit linking (opt-in).** Instead of rasterizing a native control, instantiate Apple's official
  component so it's editable. Graceful: find the component, fall back to the image if absent. Gated on the
  designer owning the kit (in-file or a team library) — parked until a consumer has it. Mapping is known:
  Switch → `Toggle - Switch` (`State` = On/Off); Segmented → `Segmented control` (`Segments`/`Selected`/`Label N`);
  match prop keys by prefix (they carry `#id` suffixes like `State#6152:0`), `createInstance()` + `setProperties()`.

### Minor polish (only if someone hits them)

- **Harden `@Pinnable`** — a clear compile diagnostic when a required marker is missing or a marked property's
  type doesn't conform, instead of a confusing downstream failure.
- **Extend `@Pinnable`** to the rest of the `Pin*` components as screens need them (`PinLabel`/`PinButton` today).
- **Vector assets (SVG/PDF)** rasterize like everything else — preserving them as Figma vector paths keeps scalability.
- **SF Symbols** are pixels today; better to map them to a Figma icon-library component via Code Connect.
- **Button variants** as Figma variant properties (one component with a `Style` prop) rather than separate masters.
- **The "Pay now" sub-pixel** — have `PinButton` emit its real laid-out label width instead of `.size`.
