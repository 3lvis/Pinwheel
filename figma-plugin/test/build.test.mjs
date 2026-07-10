import { test } from 'node:test'
import assert from 'node:assert/strict'
import { importedLabel, loadPlugin, rootParent } from './figma-mock.mjs'

test('a .center multi-line label imports center-aligned, not left', async () => {
  const label = await importedLabel({ textAlign: 'center' })
  assert.ok(label, 'the label node should be created')
  assert.equal(label.textAlignHorizontal, 'CENTER',
    'a .multilineTextAlignment(.center) label must import center-aligned (regressed to left when the bare-text flow path ignored textAlign)')
})

test('a fillWidth centered text stretches to fill, so centering is visible (UIKit Tweakable)', async () => {
  const { build, created } = loadPlugin()
  const doc = {
    tag: 'frame', name: 'Screen', x: 0, y: 0, w: 402, h: 200, ordered: true,
    layout: { mode: 'column', rowGap: 0, columnGap: 0, pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' },
    children: [{
      tag: 'text', x: 59, y: 80, w: 284, h: 20, fillWidth: true, textAlign: 'center',
      font: { family: 'SF Pro Rounded', size: 17, weight: 500, color: { r: 1, g: 1, b: 1, a: 1 } },
      texts: [{ text: 'Tap the button and choose an option.', x: 59, y: 80, w: 284, h: 20 }],
      children: [],
    }],
  }
  await build(doc, rootParent(), 0, 0, false)
  const text = created.find((n) => n.type === 'TEXT' && n.characters)
  assert.equal(text.textAlignHorizontal, 'CENTER', 'centered text aligns center')
  assert.equal(text.layoutSizingHorizontal, 'FILL', 'a fillWidth text must stretch to fill; a tight box centers to no visible effect and sits at the column leading edge (left)')
})

function themeDoc() {
  return {
    tokens: [{ name: 'primaryText', type: 'color', value: { r: 0, g: 0, b: 0, a: 1 }, dark: { r: 1, g: 1, b: 1, a: 1 } }],
    root: {
      tag: 'frame', name: 'Screen', x: 0, y: 0, w: 402, h: 100, ordered: true,
      layout: { mode: 'column', rowGap: 0, columnGap: 0, pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' },
      children: [{
        tag: 'text', x: 0, y: 0, w: 200, h: 20, textAlign: 'center',
        font: { family: 'SF Pro Rounded', size: 17, weight: 500, color: { r: 0, g: 0, b: 0, a: 1 }, colorToken: 'primaryText' },
        texts: [{ text: 'Hello', x: 0, y: 0, w: 200, h: 20 }],
        children: [],
      }],
    },
  }
}

test('a dark import binds the color/dark/<token> variable (tokenized, not baked raw hex)', async () => {
  const { syncFromDocument, importFramed, created } = loadPlugin()
  const doc = themeDoc()
  await syncFromDocument(doc)
  await importFramed(doc, 1, true, [])
  const text = created.find((n) => n.type === 'TEXT' && n.characters === 'Hello')
  const bound = text.fills[0].boundVariables && text.fills[0].boundVariables.color
  assert.ok(bound, 'a dark fill must bind a token variable, not a static hex color')
  assert.equal(bound.id, 'color/dark/primaryText', 'it binds the dark-theme variable, so dark colours stay editable tokens')
})

test('an untokenized literal colour stays a static paint, not value-matched to a token variable', async () => {
  const { syncFromDocument, importFramed, created } = loadPlugin()
  const doc = {
    // primaryBackground's light value is white; a literal white contrast label must NOT bind it by value.
    tokens: [{ name: 'primaryBackground', type: 'color', value: { r: 1, g: 1, b: 1, a: 1 }, dark: { r: 0, g: 0, b: 0, a: 1 } }],
    root: {
      tag: 'frame', name: 'Screen', x: 0, y: 0, w: 402, h: 100, ordered: true,
      layout: { mode: 'column', rowGap: 0, columnGap: 0, pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' },
      children: [{
        tag: 'text', x: 0, y: 0, w: 200, h: 20,
        font: { family: 'SF Pro Rounded', size: 17, weight: 500, color: { r: 1, g: 1, b: 1, a: 1 } },
        texts: [{ text: 'Contrast', x: 0, y: 0, w: 200, h: 20 }],
        children: [],
      }],
    },
  }
  await syncFromDocument(doc)
  await importFramed(doc, 1, true, [])
  const text = created.find((n) => n.type === 'TEXT' && n.characters === 'Contrast')
  assert.ok(!(text.fills[0].boundVariables && text.fills[0].boundVariables.color),
    'a literal colour with no token stays static — value-matching would bind the wrong token (and wrong theme)')
})

test('a light import binds the color/light/<token> variable', async () => {
  const { syncFromDocument, importFramed, created } = loadPlugin()
  const doc = themeDoc()
  await syncFromDocument(doc)
  await importFramed(doc, 1, false, [])
  const text = created.find((n) => n.type === 'TEXT' && n.characters === 'Hello')
  const bound = text.fills[0].boundVariables && text.fills[0].boundVariables.color
  assert.equal(bound && bound.id, 'color/light/primaryText', 'a light fill binds the light-theme variable')
})

test('a natural-alignment label is left by default (no over-centering)', async () => {
  const label = await importedLabel({ textAlign: undefined })
  assert.ok(label)
  assert.notEqual(label.textAlignHorizontal, 'CENTER', 'a label with no captured alignment must not be force-centered')
})

test('a label taller than one line wraps to its captured width instead of overflowing on one line', async () => {
  const label = await importedLabel({ textAlign: 'center', h: 40, texts: [{ text: 'Tap the settings button and choose an option.', x: 64, y: 380, w: 272, h: 40 }] })
  assert.equal(label.textAutoResize, 'HEIGHT', 'a multi-line label fixes its width and grows in height so Figma re-wraps it')
  assert.equal(label.width, 272, 'it wraps at the device-captured width, not its single-line hug width')
})

test('a single-line label hugs its content instead of being pinned to a wrap width', async () => {
  const label = await importedLabel({ textAlign: 'center', h: 18, texts: [{ text: 'Save', x: 64, y: 380, w: 40, h: 18 }] })
  assert.equal(label.textAutoResize, 'WIDTH_AND_HEIGHT', 'a one-line label hugs; pinning a wrap width would clip a reused instance with longer text')
})

test('makeText loads the font before writing characters (a fresh node default is unloaded)', async () => {
  const label = await importedLabel({ textAlign: 'center' })
  assert.ok(label.characters.startsWith('Tap'), 'characters are written only after the font is loaded')
})

test('a component nested in a component imports as a frame (Figma forbids component-in-component)', async () => {
  const { build, created } = loadPlugin()
  const doc = {
    tag: 'frame', component: 'Outer', name: 'Outer', x: 0, y: 0, w: 100, h: 100, ordered: true,
    layout: { mode: 'column', rowGap: 0, columnGap: 0, pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' },
    children: [{ tag: 'frame', component: 'Inner', name: 'Inner', x: 0, y: 0, w: 50, h: 50, children: [] }],
  }
  await build(doc, rootParent(), 0, 0, false)
  const inner = created.find((n) => n.name === 'Inner')
  assert.ok(inner, 'the inner node should be created')
  assert.equal(inner.type, 'FRAME', 'a component inside a component must become a frame, not a nested component')
})

test('repeated same-key cells import as one main component and the rest as instances', async () => {
  const { build, created } = loadPlugin()
  const card = (name) => ({
    tag: 'frame', component: 'Card', name: 'Row', x: 0, y: 0, w: 100, h: 40,
    texts: [{ text: name, x: 0, y: 0, w: 40, h: 20 }], font: { family: 'Inter', size: 12, weight: 400 }, children: [],
  })
  const doc = { tag: 'screen', name: 'Grid', x: 0, y: 0, w: 200, h: 200, children: [card('A'), card('B'), card('C')] }
  await build(doc, rootParent(), 0, 0, false)
  assert.equal(created.filter((n) => n.type === 'COMPONENT').length, 1, 'the first cell of a template becomes one main component')
  assert.equal(created.filter((n) => n.type === 'INSTANCE').length, 2, 'the other identical cells become instances of it, so editing the master updates them')
})
