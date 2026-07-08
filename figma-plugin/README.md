# Pinwheel Figma Capture

The Figma plugin that imports Pinwheel component captures, and the local serve it reads from.

## Setup

```sh
npm install
```

## Capture → import

1. **Serve** — hosts the capture data the plugin reads:
   ```sh
   npm run serve            # http://localhost:8787
   ```
2. **Capture** — sweep every catalog component into the serve (from the repo root):
   ```sh
   Scripts/sweep.sh --capture
   ```
   It captures each component in both simulator appearances and merges them, so imports adapt light/dark.
3. **Load the plugin** in Figma once: *Plugins → Development → Import plugin from manifest…* → `figma-plugin/manifest.json`.
4. Run **Pinwheel Capture Import**, hit **Reload catalog**, and pick a component to import (toggle **Dark version** for the dark appearance).

## Build

The plugin loads `code.js`; edit `code.ts` and recompile:

```sh
npm run build            # tsc → code.js
```

`serve.mjs` is plain Node (no build). Capture artifacts the serve writes (`catalog-*.json`, `debug.json`) are gitignored.

## Debugging an import

Every import posts a compact trace to the serve; read it to see what the plugin received and built:

```sh
curl -s http://localhost:8787/debug.json | python3 -m json.tool
```

Each entry is `{ name, rootTag, nodes, texts, images, boundStyles }`. A `rootTag` of `"screen"` is a
structured import; `"image"` means the capture produced no structured nodes and fell back to a flat
image (a capture-side problem, not the plugin). `boundStyles` is how many text runs bound a typography
token. This is always on — no toggle — so any import is diagnosable by reading one URL.
