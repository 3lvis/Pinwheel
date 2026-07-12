import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loadPlugin, rootParent } from './figma-mock.mjs'

const LAYOUT = { mode: 'row', columnGap: 0, rowGap: 0, pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' }
const frame = (children, extra = {}) => ({ tag: 'frame', x: 0, y: 0, w: 200, h: 40, ordered: true, layout: LAYOUT, children, ...extra })
const text = (value, color) => ({ tag: 'text', x: 0, y: 0, w: 40, h: 20, font: { family: 'SF', size: 14, weight: 400, color, underline: false }, texts: [{ text: value, x: 0, y: 0, w: 40, h: 20 }], children: [] })
const pill = (textColor) => ({ tag: 'frame', x: 0, y: 0, w: 40, h: 20, ordered: true, layout: LAYOUT, fill: { r: 0.9, g: 0.9, b: 0.9, a: 1 }, children: [text('chip', textColor)] })
// Two rows are one component, but the chip's TEXT colour differs per instance (Order Summary's Bonus pill is
// actionText blue, its Replaced pill is primaryText). The instance must show its own text colour.
const row = (textColor) => frame([pill(textColor)], { component: 'row' })

test('a component instance overrides a nested text colour per row', async () => {
  const { build, created } = loadPlugin()
  await build(frame([row({ r: 0, g: 0, b: 1, a: 1 }), row({ r: 1, g: 0, b: 0, a: 1 })]), rootParent(), 0, 0, false)

  const instance = created.find((node) => node.type === 'INSTANCE')
  const chipText = instance.findAllWithCriteria({ types: ['TEXT'] })[0]
  assert.ok(chipText && chipText.fills && chipText.fills[0], 'the instance chip text has a fill')
  assert.equal(chipText.fills[0].color.r, 1, "the instance text is its own colour (red), not the master's (blue)")
})
