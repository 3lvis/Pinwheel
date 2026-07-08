// Permissive CORS: the plugin UI runs on a figma.com origin.
import { createServer } from 'node:http'
import { readFileSync, writeFileSync, readdirSync, unlinkSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const captureFile = resolve(here, 'capture.json')
const slug = (value) => String(value || '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '')

createServer((request, response) => {
  response.setHeader('Access-Control-Allow-Origin', '*')
  response.setHeader('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS')
  response.setHeader('Access-Control-Allow-Headers', 'Content-Type')
  if (request.method === 'OPTIONS') {
    response.statusCode = 204
    return response.end()
  }

  if (request.url === '/catalog' && request.method === 'POST') {
    const chunks = []
    request.on('data', (chunk) => chunks.push(chunk))
    request.on('end', () => {
      const body = Buffer.concat(chunks)
      let id = 'unknown'
      try { id = slug(JSON.parse(body.toString()).id) || 'unknown' } catch {}
      const outFile = 'catalog-' + id + '.json'
      writeFileSync(resolve(here, outFile), body)
      response.setHeader('Content-Type', 'application/json')
      response.end(JSON.stringify({ ok: true, file: outFile }))
    })
    return
  }
  if (request.url === '/catalog' && request.method === 'DELETE') {
    for (const name of readdirSync(here)) if (/^catalog-.+\.json$/.test(name)) unlinkSync(resolve(here, name))
    response.setHeader('Content-Type', 'application/json')
    return response.end(JSON.stringify({ ok: true }))
  }
  if (request.url === '/manifest.json') {
    const items = readdirSync(here)
      .filter((name) => /^catalog-.+\.json$/.test(name))
      .map((name) => {
        try {
          const entry = JSON.parse(readFileSync(resolve(here, name)))
          return { id: entry.id, title: entry.title, section: entry.section, tags: entry.tags, version: entry.version, file: name }
        } catch { return null }
      })
      .filter(Boolean)
    response.setHeader('Content-Type', 'application/json')
    return response.end(JSON.stringify({ items }))
  }

  if (request.url === '/capture.json' && request.method === 'POST') {
    const chunks = []
    request.on('data', (chunk) => chunks.push(chunk))
    request.on('end', () => {
      writeFileSync(captureFile, Buffer.concat(chunks))
      response.setHeader('Content-Type', 'application/json')
      response.end(JSON.stringify({ ok: true }))
    })
    return
  }

  // Every import posts a compact trace here; GET it to diagnose what the plugin received and built.
  if (request.url === '/debug.json' && request.method === 'POST') {
    const chunks = []
    request.on('data', (chunk) => chunks.push(chunk))
    request.on('end', () => {
      writeFileSync(resolve(here, 'debug.json'), Buffer.concat(chunks))
      response.setHeader('Content-Type', 'application/json')
      response.end(JSON.stringify({ ok: true }))
    })
    return
  }

  // Only a-z/0-9/- in the name, so a request can't escape the directory.
  const catalogMatch = /^\/(catalog-[a-z0-9-]+\.json)$/.exec(request.url)
  const file = request.url === '/capture.json' ? captureFile
    : request.url === '/debug.json' ? resolve(here, 'debug.json')
    : catalogMatch ? resolve(here, catalogMatch[1])
    : null
  if (!file) {
    response.statusCode = 404
    return response.end('not found')
  }
  try {
    response.setHeader('Content-Type', 'application/json')
    response.end(readFileSync(file))
  } catch {
    response.statusCode = 404
    response.end(JSON.stringify({ error: file === captureFile ? 'run capture.mjs first' : 'no such file' }))
  }
}).listen(8787, () => console.log('serving the capture catalog on http://localhost:8787'))
