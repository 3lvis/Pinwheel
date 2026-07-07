import { test } from 'node:test'
import assert from 'node:assert/strict'
import vm from 'node:vm'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

// Runs the built plugin (code.js) in a sandbox with a minimal Figma API mock and returns its top-level
// `build`, so we can assert on the node tree it produces from a capture document — the plugin's rendering
// logic only runs inside Figma, and this is the one seam that exercises it headlessly.
function loadPlugin() {
  const code = readFileSync(fileURLToPath(new URL('../code.js', import.meta.url)), 'utf8')
  const created = []
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
  const api = {
    mixed: Symbol('mixed'),
    showUI() {},
    ui: { onmessage: null, postMessage() {} },
    createText: () => node('TEXT', { characters: '', fontSize: 12, fills: [] }),
    createFrame: () => node('FRAME', { fills: [] }),
    createRectangle: () => node('RECT', { fills: [] }),
    createComponent: () => node('COMPONENT'),
    createTextStyle: () => node('TEXTSTYLE'),
    createImage: () => ({ hash: 'image' }),
    base64Decode: () => new Uint8Array(),
    loadFontAsync: async () => {},
  }
  const figma = new Proxy(api, { get: (target, prop) => (prop in target ? target[prop] : () => {}) })
  const sandbox = { figma, __html__: '', console }
  sandbox.globalThis = sandbox
  vm.createContext(sandbox)
  vm.runInContext(code, sandbox)
  return { build: sandbox.build, created }
}

// A centered empty-state screen: one multi-line label, .multilineTextAlignment(.center), in a centered
// auto-layout column — the Tweakable "Tap the settings button…" message.
function centeredEmptyState(textAlign) {
  return {
    tag: 'screen', name: 'Tweakable', x: 0, y: 0, w: 402, h: 800,
    fill: { r: 0.1, g: 0.1, b: 0.1, a: 1 }, ordered: true,
    layout: { mode: 'column', rowGap: 0, columnGap: 0, pad: [300, 64, 300, 64], justify: 'center', align: 'center', primarySizing: 'FIXED', counterSizing: 'FIXED' },
    children: [{
      tag: 'text', x: 64, y: 380, w: 272, h: 40,
      font: { family: 'SF Pro Rounded', size: 15, weight: 400, style: 'subtitle', color: { r: 1, g: 1, b: 1, a: 1 } },
      textAlign,
      texts: [{ text: 'Tap the settings button and choose an option.', x: 64, y: 380, w: 272, h: 40 }],
      children: [],
    }],
  }
}

function node0() {
  return { type: 'ROOT', children: [], layoutMode: 'NONE', appendChild(c) { this.children.push(c); c.parent = this }, resize() {} }
}

test('a .center multi-line label imports center-aligned, not left', async () => {
  const { build, created } = loadPlugin()
  await build(centeredEmptyState('center'), node0(), 0, 0, false)
  const label = created.find((n) => n.type === 'TEXT' && typeof n.characters === 'string' && n.characters.startsWith('Tap'))
  assert.ok(label, 'the label node should be created')
  assert.equal(label.textAlignHorizontal, 'CENTER',
    'a .multilineTextAlignment(.center) label must import center-aligned (regressed to left when the bare-text flow path ignored textAlign)')
})

test('a natural-alignment label is left by default (no over-centering)', async () => {
  const { build, created } = loadPlugin()
  await build(centeredEmptyState(undefined), node0(), 0, 0, false)
  const label = created.find((n) => n.type === 'TEXT' && typeof n.characters === 'string' && n.characters.startsWith('Tap'))
  assert.ok(label, 'the label node should be created')
  assert.notEqual(label.textAlignHorizontal, 'CENTER', 'a label with no captured alignment must not be force-centered')
})
