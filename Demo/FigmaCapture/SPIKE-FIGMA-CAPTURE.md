# Spike: SwiftUI → Figma capture

Proves a Pinwheel screen can be serialized into the **same JSON** fonno's Figma plugin
already imports (`fonno/frontend/tools/figma-capture/plugin/code.ts`), so that plugin —
which builds Figma component masters/instances and binds token variables — is reused
unchanged. Source stays the design source of truth; Figma becomes the playground.

## What it does

`FigmaCaptureScreen` renders a Pinwheel screen inside `FigmaCaptureHost`, which collects
each tagged component (via an `anchorPreference` bounds sweep resolved in the screen's
coordinate space) and writes fonno's IR to `Documents/figma-capture.json`. Reach it two
ways: the **Screens** section of the catalog, or the `-FigmaCapture` launch arg. See
`sample-capture.json` for a real run.

```
xcrun simctl launch <booted> com.nordser.pinwheel -FigmaCapture
# then pull Documents/figma-capture.json → feed to the fonno plugin's "Import layers"
```

## What's proven (round-trip verified via the Figma REST API)

- The IR is source-agnostic: SwiftUI emits the identical `{width,height,root,tokens}`
  tree the DOM walker does. `serve.mjs` needs no changes.
- Geometry is real, not guessed — the `Spacer` pushed the buttons to y=654/714; those
  frames come from an actual hosted layout pass.
- Components rebuild as real Figma **masters + instances**; a repeated component (two
  Buttons) keeps its own text and fill per instance.
- Fills bind to token **variables by name** (`actionText`, `secondaryBackground`) on a
  single "Import layers" click.
- Button labels center in their frame; plain labels stay leading.

## Why iOS fits better than the web capture

- Components self-identify — no manual `data-fig` (here tagged at the call site only
  because the spike doesn't yet touch the `Pin*` sources).
- Token names are emitted directly, vs the web path's fragile RGB-value matching.

## Productionizing (not in the spike)

- Move `.figmaCapture` into the `Pin*` components so screens capture with no call-site
  tagging, and read real component props (radius, font, text alignment) instead of the
  hand-passed values here — e.g. the capture hardcodes a 24pt radius while `PinButton`
  uses a smaller one.
- Emit nested `layout` (HStack/VStack → Figma auto-layout); today every node is absolute
  under the root (the IR already supports both, so this degrades gracefully).
- Capture both light/dark; today RGBA resolves against light only.
