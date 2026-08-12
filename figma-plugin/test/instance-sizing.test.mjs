import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { loadPlugin, rootParent } from './figma-mock.mjs'

// A reflection-captured row (Cart's cards) has no measured size — w/h ≈ 0 — and fills its parent via a
// grow spacer; the master frame gets layoutSizingHorizontal = FILL. The repeated sale rows import as
// component instances, and an instance force-resized to node.w (≈0) collapses to nothing, so the rows
// overlap instead of stacking full-width. An instance that fills width must take FILL like its master.
test('a width-filling component instance imports at FILL, not collapsed to zero width', async () => {
  const cart = JSON.parse(readFileSync(fileURLToPath(new URL('../catalog-figma-cart.json', import.meta.url))))
  const { build, created } = loadPlugin()
  await build(cart.document.root, rootParent(), 0, 0, false)

  const instances = created.filter((node) => node.type === 'INSTANCE')
  assert.ok(instances.length >= 2, `Cart's repeated sale rows should import as instances (got ${instances.length})`)
  for (const instance of instances) {
    assert.equal(instance.layoutSizingHorizontal, 'FILL',
      'a 0-width, spacer-filled row instance must fill its parent width; resizing it to node.w collapses it and the rows overlap')
    assert.ok(instance.width > 1,
      `the instance must not collapse to ~0 width (got ${instance.width})`)
  }
})
