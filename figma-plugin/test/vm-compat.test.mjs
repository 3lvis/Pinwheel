import { test } from 'node:test'
import assert from 'node:assert/strict'
import { getQuickJS } from 'quickjs-emscripten'
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

// Figma runs plugins in QuickJS-on-WASM, not V8, so evaluating the bundle there catches VM-incompatible output a Node/V8 vm would silently accept.
const code = readFileSync(fileURLToPath(new URL('../code.js', import.meta.url)), 'utf8')
const stub = `
  var __html__ = '';
  var figma = {
    showUI: function () {}, notify: function () {},
    ui: { onmessage: null, postMessage: function () {} },
  };
`

test("the bundled code.js evaluates in Figma's QuickJS engine and exposes the shell", async () => {
  const QuickJS = await getQuickJS()
  const vm = QuickJS.newContext()
  try {
    const loaded = vm.evalCode(stub + '\n' + code)
    if (loaded.error) {
      const message = vm.dump(loaded.error)
      loaded.error.dispose()
      assert.fail('code.js failed to evaluate in QuickJS: ' + JSON.stringify(message))
    }
    loaded.value.dispose()
    const probe = vm.evalCode('typeof PW === "object" && typeof PW.build === "function"')
    const ok = vm.dump(probe.value)
    probe.value.dispose()
    assert.equal(ok, true, 'the bundle must fully load and expose PW.build (no VM error mid-evaluation)')
  } finally {
    vm.dispose()
  }
})
