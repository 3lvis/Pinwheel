import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loadPlugin } from './figma-mock.mjs'

// The pure core: planText turns a captured run + font into a plain descriptor of what the text node
// should be — no Figma API, so these assert on the returned object directly (the harness only loads the
// script; planText itself touches nothing mockable).
const plan = (run, font) => loadPlugin().sandbox.planText(run, font)
const body = { family: 'SF Pro Rounded', size: 15, weight: 400, color: { r: 1, g: 1, b: 1, a: 1 } }

test('planText: a run taller than ~1.5 lines fixes its width and grows in height (re-wraps)', () => {
  const p = plan({ text: 'long wrapped label', w: 272, h: 40 }, body)
  assert.equal(p.autoResize, 'HEIGHT')
  assert.equal(p.width, 272)
})

test('planText: a single-line run hugs and pins its line box to the captured height', () => {
  const p = plan({ text: 'Save', w: 40, h: 18 }, body)
  assert.equal(p.autoResize, 'WIDTH_AND_HEIGHT')
  assert.equal(p.width, null)
  assert.equal(p.lineHeight, 18)
})

test('planText: carries the fill descriptor from the font colour and its token', () => {
  const p = plan({ text: 'x', w: 40, h: 18 }, { ...body, colorToken: 'actionText' })
  assert.equal(p.fill.token, 'actionText')
  assert.deepEqual({ ...p.fill.color }, { r: 1, g: 1, b: 1, a: 1 })
})

test('planText: no fill descriptor when the font has no colour', () => {
  const p = plan({ text: 'x', w: 40, h: 18 }, { family: 'SF Pro Rounded', size: 15, weight: 400 })
  assert.equal(p.fill, null)
})
