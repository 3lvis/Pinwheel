import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loadPlugin, rootParent } from './figma-mock.mjs'

const textStyles = [
  { name: 'title', family: 'SF Pro Rounded', size: 23, weight: 500 },
  { name: 'subtitle', family: 'SF Pro Rounded', size: 20, weight: 500 },
  { name: 'body', family: 'SF Pro Rounded', size: 17, weight: 500 },
]

const textNode = (style) => ({
  tag: 'text', x: 0, y: 0, w: 60, h: 20, children: [],
  font: { family: 'SF Pro Rounded', size: 20, weight: 500, style, color: { r: 0, g: 0, b: 0, a: 1 } },
  texts: [{ text: 'Heading', x: 0, y: 0, w: 60, h: 20 }],
})

test('a text node whose font carries a style binds to that Figma text style (the typography token)', async () => {
  const { build, syncTextStyles, created } = loadPlugin()
  await syncTextStyles(textStyles)
  await build(textNode('subtitle'), rootParent(), 0, 0, false)
  const text = created.find((n) => n.type === 'TEXT')
  assert.ok(text, 'a text node is created')
  assert.ok(text.textStyleId, 'the text is bound to a typography token, not left with raw font values')
})

test('the bound style is the one matching the font.style name', async () => {
  const { build, syncTextStyles, created } = loadPlugin()
  await syncTextStyles(textStyles)
  await build(textNode('title'), rootParent(), 0, 0, false)
  const style = created.find((n) => n.type === 'TEXTSTYLE' && n.name === 'type/title')
  const text = created.find((n) => n.type === 'TEXT')
  assert.ok(style, 'a "type/title" text style is created')
  assert.equal(text.textStyleId, style.id, 'the text binds the title style, matching its font.style')
})
