// Run the live serve captures through the plugin's own import (syncFromDocument + importFramed, via the
// test mock) and report how each text renders — alignment, auto-layout sizing, and whether its color
// binds a token variable — without importing into Figma. Catches plugin-side render bugs (a fillWidth
// text left-aligning, a dark color baked static instead of tokenized) on the real captured data.
//
//   npm run verify                    # every component, light
//   npm run verify uikit-tweakable    # one component
//   npm run verify uikit-tweakable --dark
import { loadPlugin } from './test/figma-mock.mjs'

const SERVE = process.env.PINWHEEL_SERVE || 'http://localhost:8787'
const args = process.argv.slice(2)
const dark = args.includes('--dark')
const only = args.find((a) => !a.startsWith('--'))

const manifest = await (await fetch(`${SERVE}/manifest.json`)).json()
const items = manifest.items.filter((item) => !only || item.id === only)
if (!items.length) {
  console.error(only ? `no component "${only}" on the serve` : 'no components on the serve — run the capture sweep')
  process.exit(1)
}

for (const item of items) {
  const entry = await (await fetch(`${SERVE}/${item.file}`)).json()
  const { syncFromDocument, importFramed, created } = loadPlugin()
  await syncFromDocument(entry.document)
  await importFramed(entry.document, item.version, dark, item.tags)
  const texts = created.filter((node) => node.type === 'TEXT' && node.characters && node.name !== 'Time')
  console.log(`\n${item.id} v${item.version} — ${dark ? 'DARK' : 'light'} — ${texts.length} text node(s)`)
  for (const text of texts) {
    const bound = text.fills && text.fills[0] && text.fills[0].boundVariables && text.fills[0].boundVariables.color
    console.log(`  ${JSON.stringify(text.characters).slice(0, 32).padEnd(34)} align=${(text.textAlignHorizontal || 'LEFT').padEnd(6)} sizing=${(text.layoutSizingHorizontal || '-').padEnd(4)} color=${bound ? bound.id : 'static'}`)
  }
}
