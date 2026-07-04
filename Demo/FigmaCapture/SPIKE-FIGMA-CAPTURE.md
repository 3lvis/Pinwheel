# SwiftUI → Figma capture

Serializes a Pinwheel screen into the **same JSON** fonno's Figma plugin imports
(`fonno/frontend/tools/figma-capture/plugin/code.ts`), so that plugin — which builds Figma
component masters/instances, binds token variables, and creates text styles — is reused
unchanged. Source stays the design source of truth; Figma becomes the playground.

## What it does

Capture is a side effect of *rendering* — a component wrapped in `FigmaCaptureHost` reads its
own `PinCaptureKey` descriptors, resolves each anchor to a frame, and writes fonno's IR to
`Documents/figma-capture.json` on appear. No special launch mode: just render it, via the
**Screens** section of the catalog or an isolated preview deep-link.

```
# render one component in isolation (headless) → writes its JSON
xcrun simctl launch <booted> com.nordser.pinwheel -PinwheelPreview swiftui-figma-capture
# then pull Documents/figma-capture.json → feed to the fonno plugin's "Import layers"
```

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
- **Widths match the device**: the plugin measures its own render and adds letter-spacing to
  hit the captured iOS text width, compensating for SF Pro Rounded's optical-spacing difference
  (labels + "Cancel" exact; "Pay now" within a sub-pixel).

## Plan / not yet done

- **Harden `@Pinnable`** — diagnostics: a clear compile error when a required marker is missing
  or a marked property's type doesn't conform to the expected token protocol, instead of a
  confusing downstream failure.
- **Extend annotation** to the rest of the `Pin*` components as screens need them (only
  `PinLabel`/`PinButton` today).
- **Light + dark capture** — RGBA currently resolves against light only; emit both modes so the
  imported design carries both.
- **Nested auto-layout** — emit `layout` for `HStack`/`VStack` containers; today every node is
  absolute under the root (the IR already supports both, so this degrades gracefully).
- **The "Pay now" sub-pixel** — only if exactness is wanted: have `PinButton` emit its real
  laid-out label width instead of `.size`.
