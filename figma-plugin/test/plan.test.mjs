import { test } from 'node:test'
import assert from 'node:assert/strict'
import { planText, planAutoLayout } from '../plan.ts'

// The pure core imported directly — no Figma, no mock, no vm. Node strips the TS types on import.
const plan = (run, font) => planText(run, font)
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

const layout = (l) => planAutoLayout(l)

test('planAutoLayout: a centered column maps justify/align to primary/counter CENTER and keeps padding', () => {
  const p = layout({ mode: 'column', rowGap: 0, columnGap: 0, pad: [10, 20, 30, 40], justify: 'center', align: 'center', primarySizing: 'FIXED', counterSizing: 'AUTO' })
  assert.equal(p.layoutMode, 'VERTICAL')
  assert.equal(p.primaryAxisAlignItems, 'CENTER')
  assert.equal(p.counterAxisAlignItems, 'CENTER')
  assert.equal(p.primaryAxisSizingMode, 'FIXED')
  assert.equal(p.counterAxisSizingMode, 'AUTO')
  assert.equal(p.paddingTop, 10)
  assert.equal(p.paddingLeft, 40)
})

test('planAutoLayout: a grid centers on the cross axis via justify, not align-items', () => {
  const p = layout({ mode: 'column', rowGap: 0, columnGap: 0, pad: [0, 0, 0, 0], grid: true, alignContent: 'center', justify: 'center', justifyItems: 'start' })
  assert.equal(p.primaryAxisAlignItems, 'CENTER', 'grid main axis is align-content')
  assert.equal(p.counterAxisAlignItems, 'CENTER', 'grid cross axis comes from justify, not align-items')
})

test('planAutoLayout: a wrapping row carries WRAP and the row gap as counter spacing', () => {
  const p = layout({ mode: 'row', rowGap: 8, columnGap: 4, pad: [0, 0, 0, 0], wrap: true, justify: 'flex-start', align: 'flex-start' })
  assert.equal(p.layoutMode, 'HORIZONTAL')
  assert.equal(p.layoutWrap, 'WRAP')
  assert.equal(p.counterAxisSpacing, 8)
  assert.equal(p.itemSpacing, 4)
})
