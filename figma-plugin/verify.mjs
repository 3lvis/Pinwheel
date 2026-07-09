// Run the live serve captures through the plugin's own build() (via the test mock) and report how each
// text renders — alignment and auto-layout sizing — without importing into Figma. Catches plugin-side
// render bugs (e.g. a fillWidth text left-aligning) on the real captured data.
//
//   npm run verify            # every component on the serve
//   npm run verify uikit-tweakable
import { loadPlugin, rootParent } from './test/figma-mock.mjs'

const SERVE = process.env.PINWHEEL_SERVE || 'http://localhost:8787'
const only = process.argv[2]

const manifest = await (await fetch(`${SERVE}/manifest.json`)).json()
const items = manifest.items.filter((item) => !only || item.id === only)
if (!items.length) {
  console.error(only ? `no component "${only}" on the serve` : 'no components on the serve — run the capture sweep')
  process.exit(1)
}

for (const item of items) {
  const entry = await (await fetch(`${SERVE}/${item.file}`)).json()
  const { build, created } = loadPlugin()
  await build(entry.document.root, rootParent(), 0, 0, false)
  const texts = created.filter((node) => node.type === 'TEXT' && node.characters)
  console.log(`\n${item.id} v${item.version} — ${texts.length} text node(s)`)
  for (const text of texts) {
    console.log(`  ${JSON.stringify(text.characters).slice(0, 34).padEnd(36)} align=${(text.textAlignHorizontal || 'LEFT').padEnd(6)} sizing=${text.layoutSizingHorizontal || '-'}`)
  }
}
