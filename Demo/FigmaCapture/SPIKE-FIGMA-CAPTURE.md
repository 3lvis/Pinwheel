# Spike: SwiftUI → Figma capture

Proves a Pinwheel screen can be serialized into the **same JSON** fonno's Figma plugin
already imports (`fonno/frontend/tools/figma-capture/plugin/code.ts`), so that plugin —
which builds Figma component masters/instances and binds token variables — is reused
unchanged. Source stays the design source of truth; Figma becomes the playground.

## What it does

`-FigmaCapture` launch arg → `FigmaCaptureScreen` renders a Pinwheel screen inside
`FigmaCaptureHost`, which collects each tagged component (via an `anchorPreference`
bounds sweep resolved in the screen's coordinate space) and writes fonno's IR to
`Documents/figma-capture.json`. See `sample-capture.json` for a real run.

```
xcrun simctl launch <booted> com.nordser.pinwheel -FigmaCapture
# then pull Documents/figma-capture.json → feed to the fonno plugin's "Import layers"
```

## What's proven

- The IR is source-agnostic: SwiftUI emits the identical `{width,height,root,tokens}`
  tree the DOM walker does. `serve.mjs` and the plugin need no changes.
- Geometry is real, not guessed — the `Spacer` pushed the buttons to y=654/714; those
  frames come from an actual hosted layout pass.
- Tokens flow by **name** (`actionText`, …), and the primary button's captured fill is
  byte-identical to the `actionText` token — so even the plugin's current RGB-matching
  binds the fill to the variable with zero plugin edits.

## Why iOS fits better than the web capture

- Components self-identify — no manual `data-fig` (here tagged at the call site only
  because the spike doesn't yet touch the `Pin*` sources).
- Token names are emitted directly, vs the web path's fragile RGB-value matching.

## Productionizing (not in the spike)

- Move `.figmaCapture` into the `Pin*` components so screens capture with no call-site
  tagging, and resolve fonts/text from component props instead of hand-passed values.
- Emit nested `layout` (HStack/VStack → Figma auto-layout); today every node is absolute
  under the root (the IR already supports both, so this degrades gracefully).
- Capture both light/dark; today RGBA resolves against light only.
- Optional plugin upgrade: name-based token binding (Pinwheel emits exact names) instead
  of RGB matching.
