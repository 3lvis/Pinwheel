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

test('a color token syncs its rgba value', async () => {
  const { syncTokens, variableWrites } = loadPlugin()
  await syncTokens([{ name: 'actionText', type: 'color', value: { r: 0, g: 0.5, b: 1, a: 1 } }])
  const write = variableWrites.find((w) => w.name === 'color/actionText')
  assert.ok(write, 'the color token must be written to its variable')
  assert.deepEqual(write.value, { r: 0, g: 0.5, b: 1, a: 1 })
})
