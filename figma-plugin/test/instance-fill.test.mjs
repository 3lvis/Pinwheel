import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loadPlugin, rootParent } from './figma-mock.mjs'

const LAYOUT = { mode: 'row', columnGap: 0, rowGap: 0, pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' }
const frame = (children, extra = {}) => ({ tag: 'frame', x: 0, y: 0, w: 200, h: 80, ordered: true, layout: LAYOUT, children, ...extra })
const text = (value) => ({ tag: 'text', x: 0, y: 0, w: 40, h: 20, font: { family: 'SF', size: 14, weight: 400, color: { r: 0, g: 0, b: 0, a: 1 }, underline: false }, texts: [{ text: value, x: 0, y: 0, w: 40, h: 20 }], children: [] })
const pill = (rgb) => ({ tag: 'frame', x: 0, y: 0, w: 40, h: 20, ordered: true, layout: LAYOUT, fill: rgb, children: [text('chip')] })
// A row with a coloured chip; the two rows are one component but the chip's colour swaps per instance.
const row = (rgb, title) => frame([pill(rgb), text(title)], { component: 'row' })

// An instance overrides a nested fill (a chip's colour) to its own, not the master's.
test('a component instance overrides a nested fill per row', async () => {
  const { build, created } = loadPlugin()
  await build(frame([row({ r: 1, g: 0, b: 0, a: 1 }, 'A'), row({ r: 0, g: 0, b: 1, a: 1 }, 'B')]), rootParent(), 0, 0, false)

  const instance = created.find((node) => node.type === 'INSTANCE')
  const chip = (instance.children || []).find((layer) => layer.fills && layer.fills[0] && layer.fills[0].type === 'SOLID')
  assert.ok(chip, 'the instance has the coloured chip layer')
  assert.equal(chip.fills[0].color.b, 1, "the instance chip is its own colour (blue), not the master's (red)")
})
