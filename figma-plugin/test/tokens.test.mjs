import { test } from 'node:test'
import assert from 'node:assert/strict'
import { loadPlugin } from './figma-mock.mjs'

test('a float token syncs its numeric value, not the null it would crash setValueForMode with', async () => {
  const { syncTokens, variableWrites } = loadPlugin()
  await syncTokens([{ name: 'spacing-m', type: 'float', float: 16 }])
  const write = variableWrites.find((w) => w.name === 'spacing/m')
  assert.ok(write, 'the float token must be written to its variable')
  assert.equal(write.value, 16, 'a FLOAT variable takes token.float; feeding token.value (null) throws "Required value missing"')
})

test('a color token syncs light and dark to separate per-theme variables (no variable mode needed)', async () => {
  const { syncTokens, variableWrites } = loadPlugin()
  await syncTokens([{ name: 'actionText', type: 'color', value: { r: 0, g: 0.5, b: 1, a: 1 }, dark: { r: 0.1, g: 0.6, b: 1, a: 1 } }])
  const light = variableWrites.find((w) => w.name === 'color/light/actionText')
  const dark = variableWrites.find((w) => w.name === 'color/dark/actionText')
  assert.ok(light, 'a color/light/<token> variable takes the light value')
  assert.deepEqual(light.value, { r: 0, g: 0.5, b: 1, a: 1 })
  assert.ok(dark, 'a color/dark/<token> variable takes the dark value (so dark stays a token, not raw hex)')
  assert.deepEqual(dark.value, { r: 0.1, g: 0.6, b: 1, a: 1 })
})
