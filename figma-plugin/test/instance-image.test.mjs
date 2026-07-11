import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loadPlugin, rootParent } from './figma-mock.mjs'

const LAYOUT = { mode: 'row', columnGap: 0, rowGap: 0, pad: [0, 0, 0, 0], justify: 'flex-start', align: 'flex-start', primarySizing: 'FIXED', counterSizing: 'FIXED' }
const frame = (children, extra = {}) => ({ tag: 'frame', x: 0, y: 0, w: 200, h: 80, ordered: true, layout: LAYOUT, children, ...extra })
const text = (value) => ({ tag: 'text', x: 0, y: 0, w: 40, h: 20, font: { family: 'SF', size: 14, weight: 400, color: { r: 0, g: 0, b: 0, a: 1 }, underline: false }, texts: [{ text: value, x: 0, y: 0, w: 40, h: 20 }], children: [] })
const image = (bytes) => ({ tag: 'image', x: 0, y: 0, w: 64, h: 64, image: bytes, children: [] })
// A gallery row: a per-row photo beside a title. Both rows are one component; the image swaps per instance.
const row = (bytes, title) => frame([image(bytes), text(title)], { component: 'row' })

// An instance's image fill is overridden to its own photo, not left showing the master's.
test('a component instance overrides its image fill per row', async () => {
  const { build, created } = loadPlugin()
  await build(frame([row('MASTERIMG', 'A'), row('INSTIMG', 'B')]), rootParent(), 0, 0, false)

  const instance = created.find((node) => node.type === 'INSTANCE')
  const imageLayer = (instance.children || []).find((layer) => layer.fills && layer.fills[0] && layer.fills[0].type === 'IMAGE')
  assert.ok(imageLayer, 'the instance has an image layer')
  assert.equal(imageLayer.fills[0].imageHash, 'img-INSTIMG',
    "the instance shows its own photo, not the master's — an instance can swap an image fill")
})
