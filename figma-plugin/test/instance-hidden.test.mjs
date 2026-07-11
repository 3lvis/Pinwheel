import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loadPlugin, rootParent } from './figma-mock.mjs'

const LAYOUT = { mode: 'row', columnGap: 0, rowGap: 0, pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' }
const frame = (children, extra = {}) => ({ tag: 'frame', x: 0, y: 0, w: 200, h: 40, ordered: true, layout: LAYOUT, children, ...extra })
const text = (value) => ({ tag: 'text', x: 0, y: 0, w: 40, h: 20, font: { family: 'SF', size: 14, weight: 400, color: { r: 0, g: 0, b: 0, a: 1 }, underline: false }, texts: [{ text: value, x: 0, y: 0, w: 40, h: 20 }], children: [] })
const pill = (hidden) => frame([text('SALE')], hidden ? { hidden: true } : {})
// A cart row: a title with an optional SALE pill. The instance (no-sale) carries the pill as a hidden placeholder.
const row = (saleHidden) => frame([frame([text('Title'), pill(saleHidden)])], { component: 'row' })

// A normalized instance imports with its optional layers hidden, while the master keeps them visible.
test('a hidden placeholder layer is hidden on the instance but not the master', async () => {
  const { build, created } = loadPlugin()
  const doc = frame([row(false), row(true)], { component: undefined })
  await build(doc, rootParent(), 0, 0, false)

  const master = created.find((node) => node.type === 'COMPONENT')
  const instance = created.find((node) => node.type === 'INSTANCE')
  assert.ok(master && instance, 'the first row is the master component, the second an instance')

  // structure: row → titleHStack → [Title text, SALE pill]
  const masterPill = master.children[0].children[1]
  const instancePill = instance.children[0].children[1]
  assert.notEqual(masterPill.visible, false, 'the master keeps the SALE pill visible')
  assert.equal(instancePill.visible, false, 'the instance hides its SALE pill placeholder')
})
