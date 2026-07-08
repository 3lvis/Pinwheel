import { test } from 'node:test'
import assert from 'node:assert/strict'
import { importedLabel } from './figma-mock.mjs'

// Each test pins a text-rendering behavior that regressed this session — the plugin's rendering only runs
// in Figma, so these exercise it headlessly through the vm harness (see figma-mock.mjs).

test('a .center multi-line label imports center-aligned, not left', async () => {
  const label = await importedLabel({ textAlign: 'center' })
  assert.ok(label, 'the label node should be created')
  assert.equal(label.textAlignHorizontal, 'CENTER',
    'a .multilineTextAlignment(.center) label must import center-aligned (regressed to left when the bare-text flow path ignored textAlign)')
})

test('a natural-alignment label is left by default (no over-centering)', async () => {
  const label = await importedLabel({ textAlign: undefined })
  assert.ok(label)
  assert.notEqual(label.textAlignHorizontal, 'CENTER', 'a label with no captured alignment must not be force-centered')
})

test('a label taller than one line wraps to its captured width instead of overflowing on one line', async () => {
  // run.h (40) well over one line for a 15pt font: must re-wrap at the captured width.
  const label = await importedLabel({ textAlign: 'center', h: 40, texts: [{ text: 'Tap the settings button and choose an option.', x: 64, y: 380, w: 272, h: 40 }] })
  assert.equal(label.textAutoResize, 'HEIGHT', 'a multi-line label fixes its width and grows in height so Figma re-wraps it')
  assert.equal(label.width, 272, 'it wraps at the device-captured width, not its single-line hug width')
})

test('a single-line label hugs its content instead of being pinned to a wrap width', async () => {
  const label = await importedLabel({ textAlign: 'center', h: 18, texts: [{ text: 'Save', x: 64, y: 380, w: 40, h: 18 }] })
  assert.equal(label.textAutoResize, 'WIDTH_AND_HEIGHT', 'a one-line label hugs; pinning a wrap width would clip a reused instance with longer text')
})
