import vm from 'node:vm'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

// Runs the built plugin (code.js) in a sandbox with a minimal Figma API mock and returns its top-level
// functions, so tests can assert on the node tree the plugin produces from a capture document. The
// plugin's rendering only runs inside Figma; this is the seam that exercises it headlessly. `build` is the
// entry; `created` collects every node the run made so a test can find the one it cares about.
export function loadPlugin() {
  const code = readFileSync(fileURLToPath(new URL('../code.js', import.meta.url)), 'utf8')
  const created = []
  const variableWrites = []
  const node = (type, extra = {}) => {
    const made = {
      type, children: [], width: 100, height: 20, layoutMode: 'NONE',
      appendChild(child) { this.children.push(child); child.parent = this },
      resize(width, height) { this.width = width; this.height = height },
      ...extra,
    }
    created.push(made)
    return made
  }
  const collection = {
    id: 'collection', name: 'Mode', modes: [{ modeId: 'light', name: 'Mode 1' }],
    renameMode(modeId, name) { this.modes.find((m) => m.modeId === modeId).name = name },
    addMode(name) { this.modes.push({ modeId: 'dark', name }); return 'dark' },
  }
  const variablesByName = new Map()
  const api = {
    mixed: Symbol('mixed'),
    showUI() {},
    notify() {},
    ui: { onmessage: null, postMessage() {} },
    createText: () => node('TEXT', { characters: '', fontSize: 12, fills: [] }),
    createFrame: () => node('FRAME', { fills: [] }),
    createRectangle: () => node('RECT', { fills: [] }),
    createComponent: () => node('COMPONENT'),
    createTextStyle: () => node('TEXTSTYLE'),
    createImage: () => ({ hash: 'image' }),
    base64Decode: () => new Uint8Array(),
    loadFontAsync: async () => {},
    variables: {
      getLocalVariableCollectionsAsync: async () => [],
      createVariableCollection: (name) => { collection.name = name; return collection },
      getLocalVariablesAsync: async () => [...variablesByName.values()],
      createVariable: (name, coll, resolvedType) => {
        const variable = {
          name, resolvedType, variableCollectionId: coll.id, values: {},
          setValueForMode(modeId, value) { this.values[modeId] = value; variableWrites.push({ name, modeId, value }) },
          remove() { variablesByName.delete(name) },
        }
        variablesByName.set(name, variable)
        return variable
      },
      setBoundVariableForPaint: (paint) => paint,
    },
  }
  const figma = new Proxy(api, { get: (target, prop) => (prop in target ? target[prop] : () => {}) })
  const sandbox = { figma, __html__: '', console }
  sandbox.globalThis = sandbox
  vm.createContext(sandbox)
  vm.runInContext(code, sandbox)
  // The bundle is an IIFE that returns the shell entry points as the `PW` global (esbuild --global-name).
  // Pure decision logic isn't here — it's imported straight from plan.ts by the plan tests, no mock.
  return { build: sandbox.PW.build, syncTokens: sandbox.PW.syncTokens, created, variableWrites }
}

// A root parent for build() — the containing frame the plugin appends the screen into.
export function rootParent() {
  return { type: 'ROOT', children: [], layoutMode: 'NONE', appendChild(c) { this.children.push(c); c.parent = this }, resize() {} }
}

// A centered auto-layout column holding one label — the empty-state shape (Tweakable). `text` overrides
// the label node (alignment, run height for wrap, etc.).
export function labelScreen(text = {}) {
  return {
    tag: 'screen', name: 'Screen', x: 0, y: 0, w: 402, h: 800,
    fill: { r: 0.1, g: 0.1, b: 0.1, a: 1 }, ordered: true,
    layout: { mode: 'column', rowGap: 0, columnGap: 0, pad: [300, 64, 300, 64], justify: 'center', align: 'center', primarySizing: 'FIXED', counterSizing: 'FIXED' },
    children: [{
      tag: 'text', x: 64, y: 380, w: 272, h: 40,
      font: { family: 'SF Pro Rounded', size: 15, weight: 400, style: 'subtitle', color: { r: 1, g: 1, b: 1, a: 1 } },
      texts: [{ text: 'Tap the settings button and choose an option.', x: 64, y: 380, w: 272, h: 40 }],
      children: [],
      ...text,
    }],
  }
}

// The single label node created by building `labelScreen`.
export async function importedLabel(text) {
  const { build, created } = loadPlugin()
  await build(labelScreen(text), rootParent(), 0, 0, false)
  return created.find((n) => n.type === 'TEXT' && n.characters)
}
