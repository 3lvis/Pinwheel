import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loadPlugin, rootParent } from './figma-mock.mjs'

// A captured padding/radius that carries a token must import as a variable binding, not a raw number —
// otherwise every spacing and corner-radius lands untokenized in Figma. syncTokens creates the float
// variables; build must then bind them onto the frame.

test('a padding that carries a spacing token binds to that variable, not a raw number', async () => {
  const { build, syncTokens, created } = loadPlugin()
  await syncTokens([{ name: 'spacing-s', type: 'float', float: 8 }])
  await build({
    tag: 'frame', name: 'Card', x: 0, y: 0, w: 100, h: 100, ordered: true,
    layout: { mode: 'column', rowGap: 0, columnGap: 0, pad: [8, 8, 8, 8], padTokens: ['spacing-s', 'spacing-s', 'spacing-s', 'spacing-s'], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' },
    children: [],
  }, rootParent(), 0, 0, false)
  const card = created.find((n) => n.name === 'Card')
  assert.ok(card, 'the card frame should be created')
  assert.ok(card.boundVariables.paddingTop, 'paddingTop must be bound to the spacing variable, not set raw')
  assert.equal(card.boundVariables.paddingTop.name, 'spacing/s')
})

test('a gap that carries a spacing token binds itemSpacing to that variable', async () => {
  const { build, syncTokens, created } = loadPlugin()
  await syncTokens([{ name: 'spacing-l', type: 'float', float: 16 }])
  await build({
    tag: 'frame', name: 'Stack', x: 0, y: 0, w: 100, h: 100, ordered: true,
    layout: { mode: 'column', rowGap: 16, columnGap: 0, gapToken: 'spacing-l', pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' },
    children: [],
  }, rootParent(), 0, 0, false)
  const stack = created.find((n) => n.name === 'Stack')
  assert.ok(stack, 'the stack frame should be created')
  assert.ok(stack.boundVariables.itemSpacing, 'itemSpacing must bind to the spacing variable, not set raw')
  assert.equal(stack.boundVariables.itemSpacing.name, 'spacing/l')
})

test('a corner radius that carries a radius token binds to that variable', async () => {
  const { build, syncTokens, created } = loadPlugin()
  await syncTokens([{ name: 'radius-m', type: 'float', float: 12 }])
  await build({
    tag: 'frame', name: 'Rounded', x: 0, y: 0, w: 100, h: 100, radius: 12, radiusToken: 'radius-m', children: [],
  }, rootParent(), 0, 0, false)
  const rounded = created.find((n) => n.name === 'Rounded')
  assert.ok(rounded, 'the frame should be created')
  assert.ok(rounded.boundVariables.topLeftRadius, 'the corner radius must be bound to the radius variable')
  assert.equal(rounded.boundVariables.topLeftRadius.name, 'radius/m')
})
