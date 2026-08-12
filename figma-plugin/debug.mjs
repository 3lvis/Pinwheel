// Pull the live import trace the plugin flushed to /debug.json (populated when you Import in Figma) and
// diff each imported component against the captured IR on the serve — keyed on the stable `id`, so the
// SwiftUI/UIKit twins ("Button", "StateView", …) that share a title never collide.
//
//   npm run debug          # diff the last import against the captures
import { readFileSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const SERVE = process.env.PINWHEEL_SERVE || 'http://localhost:8787'
const here = dirname(fileURLToPath(import.meta.url))
const getJSON = async (path) => (await fetch(`${SERVE}${path}`)).json()

const trace = await getJSON('/debug.json')
const { items } = await getJSON('/manifest.json')
const fileById = new Map(items.map((item) => [item.id, item.file]))

const luminance = (c) => (c ? 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b : null)

function countIR(doc) {
  let nodes = 0, texts = 0, images = 0
  const walk = (node) => {
    nodes += 1
    if (node.texts) texts += node.texts.length
    if (node.image) images += 1
    for (const child of node.children || []) walk(child)
  }
  walk(doc.root)
  const root = doc.root
  // Visual health the node counts can't see: a screen must have a background, and a light capture's
  // background must actually be light + tokenized (a dark, untokenized root = the sweep captured the
  // wrong appearance and it's baked, so it won't adapt).
  const rootFill = root.fill || null
  const issues = []
  if (!rootFill && !root.fillToken) issues.push('NO-BG')
  else if (rootFill && luminance(rootFill) < 0.3 && !root.fillToken) issues.push('DARK-BG(untokenized)')
  return { nodes, texts, images, issues }
}

const idsPresent = trace.every((entry) => entry.id)
if (!idsPresent) {
  console.log('note: this trace predates the id-carrying plugin — pairing by import order (re-import to key by id).\n')
}

const rows = trace.map((entry, index) => ({
  entry,
  id: entry.id || items[index]?.id || `#${index}`,
}))

const pad = (value, width) => String(value).padEnd(width)
console.log(`${pad('id', 28)}${pad('root', 8)}${pad('nodes i/c', 12)}${pad('text i/c', 11)}${pad('img i/c', 10)}verdict`)
console.log('-'.repeat(82))

const mismatches = []
for (const { entry, id } of rows) {
  const file = fileById.get(id)
  const cap = file ? countIR((await getJSON(`/${file}`)).document) : null
  let verdict = 'ok'
  if (!cap) verdict = 'NO CAPTURE'
  else if (entry.nodes !== cap.nodes || entry.texts !== cap.texts || entry.images !== cap.images) verdict = 'DIFF'
  if (entry.rootTag === 'image') verdict = 'FLAT-IMAGE'
  if (cap && cap.issues.length) verdict = cap.issues.join(',')
  if (verdict !== 'ok') mismatches.push(id)
  const ic = (a, b) => `${a}/${b ?? '?'}`
  console.log(
    pad(id, 28) + pad(entry.rootTag, 8) +
    pad(ic(entry.nodes, cap?.nodes), 12) + pad(ic(entry.texts, cap?.texts), 11) +
    pad(ic(entry.images, cap?.images), 10) + verdict
  )
}

console.log()
console.log(mismatches.length
  ? `mismatches: ${mismatches.join(', ')}`
  : `all ${rows.length} components imported exactly as captured (i=imported, c=captured)`)
